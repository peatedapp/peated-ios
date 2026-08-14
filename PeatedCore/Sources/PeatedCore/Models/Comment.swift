import Foundation
import PeatedAPI

/// Represents a comment on a tasting
public struct Comment: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let text: String
    public let createdAt: Date

    // User info (denormalized for performance)
    public let userId: String
    public let username: String
    public let userDisplayName: String?
    public let userAvatarUrl: String?

    /// Tasting reference
    public let tastingId: String

    /// Creates a new Comment instance
    public init(
        id: String,
        text: String,
        createdAt: Date,
        userId: String,
        username: String,
        userDisplayName: String?,
        userAvatarUrl: String?,
        tastingId: String
    ) {
        self.id = id
        self.text = text
        self.createdAt = createdAt
        self.userId = userId
        self.username = username
        self.userDisplayName = userDisplayName
        self.userAvatarUrl = userAvatarUrl
        self.tastingId = tastingId
    }

    /// Display name for the comment author
    public var authorDisplayName: String {
        userDisplayName ?? username
    }

    /// Relative time display (e.g., "2 hours ago")
    public var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}

// MARK: - API Response Mapping

public extension Comment {
    /// Creates a Comment from API response
    init(from apiComment: Components.Schemas.Comment, tastingId: String) {
        self.init(
            id: String(Int(apiComment.id)),
            text: apiComment.comment,
            createdAt: apiComment.createdAt,
            userId: String(Int(apiComment.createdBy.id)),
            username: apiComment.createdBy.username,
            userDisplayName: nil,
            userAvatarUrl: apiComment.createdBy.pictureUrl,
            tastingId: tastingId
        )
    }
}
