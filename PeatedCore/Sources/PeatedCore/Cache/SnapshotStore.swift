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

public enum SnapshotStore {
  private static func userSnapshotKey(_ id: String) -> CacheKey { CacheKey("userSnapshot:\(id)") }
  private static func userRecentKey(_ id: String) -> CacheKey { CacheKey("userRecent:\(id)") }

  public static func upsertUser(_ snapshot: UserProfileSnapshot) async {
    await NormalizedStore.shared.upsert(userSnapshotKey(snapshot.id), value: snapshot)
  }

  public static func getUser(_ id: String) async -> UserProfileSnapshot? {
    await NormalizedStore.shared.get(userSnapshotKey(id), as: UserProfileSnapshot.self)?.0
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
}

