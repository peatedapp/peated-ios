import Foundation

public struct CacheKey: Hashable, Codable, Sendable {
  public let raw: String
  public init(_ raw: String) { self.raw = raw }
  public static func user(_ id: String) -> CacheKey { .init("user:\(id)") }
  public static func bottle(_ id: String) -> CacheKey { .init("bottle:\(id)") }
  public static func entity(_ id: String) -> CacheKey { .init("entity:\(id)") }
}

public struct CacheMetadata: Codable, Equatable, Sendable {
  public var etag: String?
  public var lastModified: Date?
  public var expiry: Date?
  public init(etag: String? = nil, lastModified: Date? = nil, expiry: Date? = nil) {
    self.etag = etag
    self.lastModified = lastModified
    self.expiry = expiry
  }
}

public actor NormalizedStore {
  public static let shared = NormalizedStore()

  private var values: [CacheKey: Data] = [:]
  private var metas: [CacheKey: CacheMetadata] = [:]
  private let encoder = JSONEncoder()
  private let decoder = JSONDecoder()
  private let storeURL: URL
  private var pendingSaveTask: Task<Void, Never>? = nil
  private let saveDebounceNanos: UInt64 = 1_500_000_000 // 1.5s

  public init() {
    // Determine store URL in Application Support
    let fm = FileManager.default
    let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? fm.temporaryDirectory
    let dir = base.appendingPathComponent("com.peated.cache", isDirectory: true)
    try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
    self.storeURL = dir.appendingPathComponent("normalized_store.json")
    // Attempt to load snapshot from disk
    if let data = try? Data(contentsOf: storeURL),
       let snap = try? decoder.decode(Snapshot.self, from: data) {
      self.values = snap.values
      self.metas = snap.metas
    }
  }

  public func get<T: Codable>(_ key: CacheKey, as type: T.Type) -> (T, CacheMetadata)? {
    guard let data = values[key] else { return nil }
    guard let value = try? decoder.decode(T.self, from: data) else { return nil }
    return (value, metas[key] ?? CacheMetadata())
  }

  public func upsert<T: Codable>(_ key: CacheKey, value: T, metadata: CacheMetadata = CacheMetadata()) {
    if let data = try? encoder.encode(value) {
      values[key] = data
      metas[key] = metadata
      scheduleSave()
    }
  }

  public func metadata(for key: CacheKey) -> CacheMetadata? { metas[key] }
  public func remove(_ key: CacheKey) { values.removeValue(forKey: key); metas.removeValue(forKey: key); scheduleSave() }
  public func clear() { values.removeAll(); metas.removeAll(); scheduleSave() }

  public func flush() {
    saveToDisk()
  }

  private func saveToDisk() {
    let snap = Snapshot(values: values, metas: metas)
    if let data = try? encoder.encode(snap) {
      try? data.write(to: storeURL, options: .atomic)
    }
  }

  private func scheduleSave() {
    pendingSaveTask?.cancel()
    pendingSaveTask = Task { [storeURL] in
      // Debounce delay
      try? await Task.sleep(nanoseconds: saveDebounceNanos)
      await saveToDisk()
    }
  }

  // TODO: Migrate cache hit/miss logging to tracing spans (Sentry) for richer insights

  private struct Snapshot: Codable {
    let values: [CacheKey: Data]
    let metas: [CacheKey: CacheMetadata]
  }
}
