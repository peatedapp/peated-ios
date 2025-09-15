import Foundation

public struct UserProfileSnapshot: Codable, Equatable, Sendable {
  public let id: String
  public var username: String?
  public var pictureUrl: String?
  public var tastingsCount: Int?
  public var bottlesCount: Int?
  public var collectedCount: Int?
  public var contributionsCount: Int?
  public var friendStatus: User.FriendStatus?

  public init(
    id: String,
    username: String? = nil,
    pictureUrl: String? = nil,
    tastingsCount: Int? = nil,
    bottlesCount: Int? = nil,
    collectedCount: Int? = nil,
    contributionsCount: Int? = nil,
    friendStatus: User.FriendStatus? = nil
  ) {
    self.id = id
    self.username = username
    self.pictureUrl = pictureUrl
    self.tastingsCount = tastingsCount
    self.bottlesCount = bottlesCount
    self.collectedCount = collectedCount
    self.contributionsCount = contributionsCount
    self.friendStatus = friendStatus
  }
}

public struct BottleSnapshot: Codable, Equatable, Sendable {
  public let id: String
  public var fullName: String?
  public var brandId: String?
  public var brandName: String?
  public var imageUrl: String?
  public init(id: String, fullName: String? = nil, brandId: String? = nil, brandName: String? = nil, imageUrl: String? = nil) {
    self.id = id
    self.fullName = fullName
    self.brandId = brandId
    self.brandName = brandName
    self.imageUrl = imageUrl
  }
}

public struct EntitySnapshot: Codable, Equatable, Sendable {
  public let id: String
  public var name: String?
  public var type: Entity.EntityType?
  public var imageUrl: String?
  public init(id: String, name: String? = nil, type: Entity.EntityType? = nil, imageUrl: String? = nil) {
    self.id = id
    self.name = name
    self.type = type
    self.imageUrl = imageUrl
  }
}

public enum SnapshotStore {
  private static func userSnapshotKey(_ id: String) -> CacheKey { CacheKey("userSnapshot:\(id)") }
  private static func userRecentKey(_ id: String) -> CacheKey { CacheKey("userRecent:\(id)") }
  private static func bottleSnapshotKey(_ id: String) -> CacheKey { CacheKey("bottleSnapshot:\(id)") }
  private static func entitySnapshotKey(_ id: String) -> CacheKey { CacheKey("entitySnapshot:\(id)") }

  public static func upsertUser(_ snapshot: UserProfileSnapshot) async {
    await NormalizedStore.shared.upsert(userSnapshotKey(snapshot.id), value: snapshot)
  }

  public static func getUser(_ id: String) async -> UserProfileSnapshot? {
    await NormalizedStore.shared.get(userSnapshotKey(id), as: UserProfileSnapshot.self)?.0
  }

  public static func upsertBottle(_ snapshot: BottleSnapshot) async {
    await NormalizedStore.shared.upsert(bottleSnapshotKey(snapshot.id), value: snapshot)
  }

  public static func getBottle(_ id: String) async -> BottleSnapshot? {
    await NormalizedStore.shared.get(bottleSnapshotKey(id), as: BottleSnapshot.self)?.0
  }

  public static func upsertEntity(_ snapshot: EntitySnapshot) async {
    await NormalizedStore.shared.upsert(entitySnapshotKey(snapshot.id), value: snapshot)
  }

  public static func getEntity(_ id: String) async -> EntitySnapshot? {
    await NormalizedStore.shared.get(entitySnapshotKey(id), as: EntitySnapshot.self)?.0
  }

  /// Append tasting IDs to a user's recent list (MRU, capped, deduped)
  public static func appendUserRecent(userId: String, tastingIds: [String], cap: Int = 20) async {
    let key = userRecentKey(userId)
    var current: [String] = await NormalizedStore.shared.get(key, as: [String].self)?.0 ?? []
    // Deduplicate preserving new order at front
    var seen = Set<String>()
    var next: [String] = []
    for id in tastingIds + current {
      if seen.insert(id).inserted { next.append(id) }
      if next.count >= cap { break }
    }
    await NormalizedStore.shared.upsert(key, value: next)
  }

  public static func getUserRecent(userId: String, limit: Int = 10) async -> [String] {
    let ids = await NormalizedStore.shared.get(userRecentKey(userId), as: [String].self)?.0 ?? []
    return Array(ids.prefix(limit))
  }

  // MARK: - Pruning
  public static func pruneAll(defaultCap: Int = 2000,
                              userSnapshotCap: Int = 500,
                              bottleSnapshotCap: Int = 1000,
                              entitySnapshotCap: Int = 1000) async {
    await NormalizedStore.shared.pruneExpired()
    await NormalizedStore.shared.pruneByPrefix(prefix: "userSnapshot:", maxEntries: userSnapshotCap)
    await NormalizedStore.shared.pruneByPrefix(prefix: "bottleSnapshot:", maxEntries: bottleSnapshotCap)
    await NormalizedStore.shared.pruneByPrefix(prefix: "entitySnapshot:", maxEntries: entitySnapshotCap)
    await NormalizedStore.shared.pruneTotal(maxEntries: defaultCap)
  }
}

// MARK: - Merging helpers (prefer non-nil from cached)
extension SnapshotStore {
  public static func merge(_ seed: UserProfileSnapshot?, _ cached: UserProfileSnapshot?) -> UserProfileSnapshot? {
    guard seed != nil || cached != nil else { return nil }
    var out = seed ?? UserProfileSnapshot(id: cached!.id)
    let c = cached
    if let v = c?.username { out.username = v }
    if let v = c?.pictureUrl { out.pictureUrl = v }
    if let v = c?.tastingsCount { out.tastingsCount = v }
    if let v = c?.bottlesCount { out.bottlesCount = v }
    if let v = c?.collectedCount { out.collectedCount = v }
    if let v = c?.contributionsCount { out.contributionsCount = v }
    if let v = c?.friendStatus { out.friendStatus = v }
    return out
  }

  public static func merge(_ seed: BottleSnapshot?, _ cached: BottleSnapshot?) -> BottleSnapshot? {
    guard seed != nil || cached != nil else { return nil }
    var out = seed ?? BottleSnapshot(id: cached!.id)
    let c = cached
    if let v = c?.fullName { out.fullName = v }
    if let v = c?.brandId { out.brandId = v }
    if let v = c?.brandName { out.brandName = v }
    if let v = c?.imageUrl { out.imageUrl = v }
    return out
  }

  public static func merge(_ seed: EntitySnapshot?, _ cached: EntitySnapshot?) -> EntitySnapshot? {
    guard seed != nil || cached != nil else { return nil }
    var out = seed ?? EntitySnapshot(id: cached!.id)
    let c = cached
    if let v = c?.name { out.name = v }
    if let v = c?.type { out.type = v }
    if let v = c?.imageUrl { out.imageUrl = v }
    return out
  }
}
