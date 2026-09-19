import Foundation

/// A member's one current opinion of a bottle, scored 0 through 100.
public struct MemberReviewFeedItem: Identifiable, Hashable, Sendable {
    public let id: String
    public let score: Int
    public let notes: String?
    public let imageUrl: String?
    public let tags: [String]
    public let createdAt: Date

    public let userId: String
    public let username: String
    public let userAvatarUrl: String?

    public let bottle: ActivityBottleSummary

    public init(
        id: String,
        score: Int,
        notes: String?,
        imageUrl: String?,
        tags: [String],
        createdAt: Date,
        userId: String,
        username: String,
        userAvatarUrl: String?,
        bottle: ActivityBottleSummary
    ) {
        self.id = id
        self.score = score
        self.notes = notes
        self.imageUrl = imageUrl
        self.tags = tags
        self.createdAt = createdAt
        self.userId = userId
        self.username = username
        self.userAvatarUrl = userAvatarUrl
        self.bottle = bottle
    }

    /// The Peated rating band the score falls in.
    public var ratingBand: TastingRatingBand? {
        TastingRatingBand(score: score)
    }
}
