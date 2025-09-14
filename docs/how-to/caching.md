# Caching & Offline Playbook (iOS, Swift)

This guide documents pragmatic, low‑flicker caching patterns for Peated’s iOS app. It favors instant UI from cached snapshots with background refresh (SWR), conditional HTTP requests, and a small normalized cache for reusing data across screens.

## Goals
- Instant render: show last snapshot immediately; avoid loading skeletons for known data (e.g., usernames, bottle names).
- Fresh‑enough: refresh in the background; animate minimal diffs when new data arrives.
- Fewer network hits: leverage HTTP cache semantics and conditional GETs (ETag/Last-Modified).
- Reuse: one shared cache so lists seed detail screens without re‑fetching.

## Layers (at a glance)
- Memory: NSCache (fast, auto‑evicts) for decoded models.
- HTTP: URLCache (honor Cache-Control, Expires), plus conditional GETs (If-None-Match / If-Modified-Since).
- Normalized store: app‑level map keyed by "type:id" that stores snapshots + metadata.
- (Optional) Disk: JSON/SQLite backing for the normalized store for warm launches.

## Core Patterns
- Stale‑While‑Revalidate (SWR):
  - Render cached snapshot immediately; mark as `isRefreshing`.
  - Fire network with conditional headers; on 304 keep snapshot; on 200 merge + update.
- Normalized cache (even for REST):
  - Store by identity key (e.g., `user:123`, `bottle:42`).
  - Lists write the same entities used by detail screens.
- Resource policies:
  - Stable identity (username, bottle/entity names): cache strongly; refresh rarely.
  - Slowly changing (stats, favorites counts): SWR with modest TTL.
  - Fast changing (feeds): SWR with short TTL, still render snapshot first.

---

## Setup Snippets

### URLCache (HTTP cache)
```swift
// AppDelegate/SceneDelegate or AppView.onAppear
let memory = 16 * 1024 * 1024   // 16 MB
let disk   = 100 * 1024 * 1024  // 100 MB
URLCache.shared = URLCache(memoryCapacity: memory, diskCapacity: disk, diskPath: "com.peated.urlcache")

let config = URLSessionConfiguration.default
config.requestCachePolicy = .useProtocolCachePolicy
config.urlCache = .shared
// Pass config into API transport if you manage your own URLSession
```

### NormalizedStore (memory, optional disk)
```swift
import Foundation

// Keyed by "type:id" (e.g., "user:123")
public struct CacheKey: Hashable, Codable { let raw: String }

public struct CacheMetadata: Codable {
  var etag: String?
  var lastModified: Date?
  var expiry: Date? // TTL cutoff (optional)
}

public struct CacheEntry<T: Codable>: Codable {
  var value: T
  var metadata: CacheMetadata
  var updatedAt: Date
}

public actor NormalizedStore {
  public static let shared = NormalizedStore()
  private var memory: [CacheKey: Data] = [:] // JSON blobs to avoid generic erasure issues
  private var metas: [CacheKey: CacheMetadata] = [:]

  public func get<T: Codable>(_ key: CacheKey, as type: T.Type) -> (T, CacheMetadata)? {
    guard let data = memory[key], let meta = metas[key] else { return nil }
    if let value = try? JSONDecoder().decode(T.self, from: data) { return (value, meta) }
    return nil
  }

  public func upsert<T: Codable>(_ key: CacheKey, value: T, metadata: CacheMetadata) {
    if let data = try? JSONEncoder().encode(value) {
      memory[key] = data
      metas[key] = metadata
    }
  }

  public func metadata(for key: CacheKey) -> CacheMetadata? { metas[key] }
}
```

### APIClient hooks (conditional requests)
```swift
// Pseudocode: integrate where requests are built and responses handled
struct ConditionalHeaders { let ifNoneMatch: String?; let ifModifiedSince: String? }

func conditionalHeaders(for key: CacheKey) async -> ConditionalHeaders {
  if let meta = await NormalizedStore.shared.metadata(for: key) {
    return ConditionalHeaders(ifNoneMatch: meta.etag,
                              ifModifiedSince: meta.lastModified?.rfc1123String)
  }
  return ConditionalHeaders(ifNoneMatch: nil, ifModifiedSince: nil)
}

func storeMetadata(from httpResponse: HTTPURLResponse, for key: CacheKey) async {
  var meta = await NormalizedStore.shared.metadata(for: key) ?? CacheMetadata()
  if let etag = httpResponse.value(forHTTPHeaderField: "ETag") { meta.etag = etag }
  if let lm   = httpResponse.value(forHTTPHeaderField: "Last-Modified")?.toDateRFC1123() { meta.lastModified = lm }
  // Value is persisted separately; this only updates metadata.
  // (Call upsert again when you save the new value.)
}
```

> Implementation detail: attach `If-None-Match` / `If-Modified-Since` if present; on 304, keep cached body and update metadata; on 200, merge + store.

### Repository helper (SWR)
```swift
public struct Cached<T> { public let value: T; public let isRefreshing: Bool }

public actor UserRepositoryCached {
  let api: APIClient
  let store = NormalizedStore.shared

  func getUserSWR(id: String) async throws -> Cached<User> {
    let key = CacheKey(raw: "user:\(id)")
    var snapshot: User?
    if let (cached, _) = await store.get(key, as: User.self) { snapshot = cached }

    // Kick off refresh with conditional headers
    let headers = await conditionalHeaders(for: key)
    Task { try? await refreshUser(id: id, key: key, headers: headers) }

    if let snapshot { return Cached(value: snapshot, isRefreshing: true) }
    let fresh = try await refreshUser(id: id, key: key, headers: headers)
    return Cached(value: fresh, isRefreshing: false)
  }

  @discardableResult
  private func refreshUser(id: String, key: CacheKey, headers: ConditionalHeaders) async throws -> User {
    let (user, response) = try await api.getUser(id: id, conditional: headers) // extend APIClient
    // Merge: prefer incoming non-nil fields
    var merged = user
    if let (old, _) = await store.get(key, as: User.self) {
      if merged.username.isEmpty { merged.username = old.username }
      if merged.pictureUrl == nil { merged.pictureUrl = old.pictureUrl }
    }
    // Store value and metadata
    let meta = CacheMetadata(etag: response.etag, lastModified: response.lastModified, expiry: nil)
    await store.upsert(key, value: merged, metadata: meta)
    return merged
  }
}
```

### ViewModel usage (no flicker)
```swift
@MainActor
final class ProfileVM: ObservableObject {
  @Published var user: User?
  @Published var isRefreshing = false
  private let repo = UserRepositoryCached(api: APIClient())
  let userId: String

  init(userId: String) { self.userId = userId }

  func load() async {
    do {
      let cached = try await repo.getUserSWR(id: userId)
      self.user = cached.value
      self.isRefreshing = cached.isRefreshing
    } catch { /* handle */ }
  }
}
```

---

## Seeding From Navigation (reuse what we have)
- Pass partial models to detail screens (e.g., `Bottle` from a list).
- On appear: upsert the seed into `NormalizedStore` (if newer), then call `getSWR` (which will render immediately and refresh in background).

```swift
// In a list -> detail navigation
NavigationLink(destination: BottleDetailView(bottleId: b.id, seed: b)) { BottleRow(bottle: b) }
```

---

## Images (optional)
- Keep `AsyncImage` now; it already uses URLCache.
- If needed later, migrate to Nuke/Kingfisher for multi‑tier caches, decoding, and preheating.
- “Preheating” = preloading images just off‑screen to avoid decode jank; only add if we see stutter.

---

## Background Refresh (optional)
- Use `BGAppRefreshTask` to occasionally refresh “me” and Favorites so launches feel warm.
- Write into `NormalizedStore`; views will render warm data instantly.

---

## Invalidation & Merge Rules
- Identity fields (username, bottle/entity names) persist unless explicitly changed by user action.
- Prefer incoming non‑nil values; do not blank out cached values unless server explicitly returns empty.
- TTLs per resource type (optional): after expiry, still show snapshot, but prioritize refresh sooner.
- Manual busting: on profile edit or friend/unfriend, immediately update cache and optionally revalidate.

---

## Testing
- Snapshot‑first UI: ensure detail screens render with cache only, then update after a simulated 304/200.
- Offline mode: kill network and verify screens use cache without flicker.
- Conditional headers: unit test ETag/Last‑Modified handling and 304 path.

---

## Migration path (phase 2)
- Add disk persistence to `NormalizedStore` (JSON per key or SQLite) with a simple versioned schema.
- Add image pipeline library if scrolling performance requires it.

---

## Where to apply first
- Profile (username/picture stable, stats SWR)
- Bottle Detail & Entity Detail (names/brand stable, stats SWR)
- Favorites list (snapshot first, pull‑to‑refresh still works)

---

## Appendix: Helpers
```swift
extension Date {
  var rfc1123String: String {
    let fmt = DateFormatter(); fmt.locale = .init(identifier: "en_US_POSIX"); fmt.timeZone = .init(secondsFromGMT: 0)
    fmt.dateFormat = "EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'"; return fmt.string(from: self)
  }
}

extension HTTPURLResponse {
  var etag: String? { value(forHTTPHeaderField: "ETag") }
  var lastModified: Date? { value(forHTTPHeaderField: "Last-Modified").flatMap { $0.toDateRFC1123() } }
}

extension String {
  func toDateRFC1123() -> Date? {
    let fmt = DateFormatter(); fmt.locale = .init(identifier: "en_US_POSIX"); fmt.timeZone = .init(secondsFromGMT: 0)
    fmt.dateFormat = "EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'"; return fmt.date(from: self)
  }
}
```

---

## TL;DR Implementation Order
1) Add `NormalizedStore` actor + conditional headers in `APIClient`.
2) Update repositories to return snapshot first, then refresh.
3) Seed details from lists, and remove loading placeholders for known data.
4) Consider disk persistence and image pipeline later if needed.

