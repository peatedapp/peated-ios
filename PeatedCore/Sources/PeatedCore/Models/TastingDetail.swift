import Foundation
import PeatedAPI

/// Represents detailed tasting information including comments and toasts
public struct TastingDetail: Identifiable, Equatable {
    public let id: String
    public let rating: Double
    public let notes: String?
    public let servingStyle: String?
    public let imageUrl: String?
    public let createdAt: Date

    // User info
    public let userId: String
    public let username: String
    public let userDisplayName: String?
    public let userAvatarUrl: String?

    // Bottle info
    public let bottleId: String
    public let bottleName: String
    public let bottleBrandName: String
    public let bottleCategory: String?
    public let bottleImageUrl: String?

    // Social data
    public var toastCount: Int
    public var commentCount: Int
    public var hasToasted: Bool

    // Lists
    public let tags: [String]
    public let location: Location?
    public var comments: [Comment]
    public var toasts: [Toast]

    public struct Location: Codable, Equatable {
        public let name: String
        public let latitude: Double?
        public let longitude: Double?
    }

    public struct Toast: Identifiable, Equatable {
        public let id: String
        public let userId: String
        public let username: String
        public let userDisplayName: String?
        public let userAvatarUrl: String?
        public let createdAt: Date
    }

    /// Relative time display
    public var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }

    /// Display name for the tasting author
    public var authorDisplayName: String {
        userDisplayName ?? username
    }
}

// MARK: - Conversion from TastingFeedItem

public extension TastingDetail {
    /// Creates a TastingDetail from a TastingFeedItem (partial data)
    init(from feedItem: TastingFeedItem) {
        id = feedItem.id
        rating = feedItem.rating
        notes = feedItem.notes
        servingStyle = feedItem.servingStyle
        imageUrl = feedItem.imageUrl
        createdAt = feedItem.createdAt
        userId = feedItem.userId
        username = feedItem.username
        userDisplayName = feedItem.userDisplayName
        userAvatarUrl = feedItem.userAvatarUrl
        bottleId = feedItem.bottleId
        bottleName = feedItem.bottleName
        bottleBrandName = feedItem.bottleBrandName
        bottleCategory = feedItem.bottleCategory
        bottleImageUrl = feedItem.bottleImageUrl
        toastCount = feedItem.toastCount
        commentCount = feedItem.commentCount
        hasToasted = feedItem.hasToasted
        tags = feedItem.tags
        location = feedItem.location.map { locName in
            Location(name: locName, latitude: nil, longitude: nil)
        }
        comments = []
        toasts = []
    }

    /// Converts TastingDetail to TastingFeedItem for use in feed card views
    func toFeedItem() -> TastingFeedItem {
        TastingFeedItem(
            id: id,
            rating: rating,
            notes: notes,
            servingStyle: servingStyle,
            imageUrl: imageUrl,
            createdAt: createdAt,
            userId: userId,
            username: username,
            userDisplayName: userDisplayName,
            userAvatarUrl: userAvatarUrl,
            bottleId: bottleId,
            bottleName: bottleName,
            bottleBrandName: bottleBrandName,
            bottleCategory: bottleCategory,
            bottleImageUrl: bottleImageUrl,
            toastCount: toastCount,
            commentCount: commentCount,
            hasToasted: hasToasted,
            tags: tags,
            location: location?.name,
            friendUsernames: []
        )
    }
}

// MARK: - API Response Mapping

public extension TastingDetail {
    /// Creates a TastingDetail from API response
    init?(from _: Components.Schemas.Tasting?) {
        // TODO: Implement proper API response mapping when the API structure is clearer
        // For now, we'll use the feedItem conversion in the view
        nil
    }
}
