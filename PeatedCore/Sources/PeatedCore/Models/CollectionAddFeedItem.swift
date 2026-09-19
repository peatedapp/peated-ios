import Foundation

/// Bottles one member added to a collection within a short window.
public struct CollectionAddFeedItem: Identifiable, Hashable, Sendable {
    public let id: String
    public let createdAt: Date

    public let userId: String
    public let username: String
    public let userAvatarUrl: String?

    /// True for the member's library, which the feed names as "their library".
    public let isLibrary: Bool
    public let collectionName: String
    /// Bottles added in the window; can exceed `bottles.count`.
    public let totalBottles: Int
    public let bottles: [ActivityBottleSummary]

    public init(
        id: String,
        createdAt: Date,
        userId: String,
        username: String,
        userAvatarUrl: String?,
        isLibrary: Bool,
        collectionName: String,
        totalBottles: Int,
        bottles: [ActivityBottleSummary]
    ) {
        self.id = id
        self.createdAt = createdAt
        self.userId = userId
        self.username = username
        self.userAvatarUrl = userAvatarUrl
        self.isLibrary = isLibrary
        self.collectionName = collectionName
        self.totalBottles = totalBottles
        self.bottles = bottles
    }

    /// Matches the web wording: "added a bottle to their library".
    public var actionText: String {
        let count = totalBottles == 1 ? "a bottle" : "\(totalBottles) bottles"
        let destination = isLibrary ? "their library" : collectionName
        return "added \(count) to \(destination)"
    }

    public var hiddenBottleCount: Int {
        max(0, totalBottles - bottles.count)
    }
}
