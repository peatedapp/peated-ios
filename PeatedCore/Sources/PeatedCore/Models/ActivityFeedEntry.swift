import Foundation

/// One row of the activity feed. The API returns tastings, member reviews,
/// critic reviews, and collection additions as one chronological list.
public enum ActivityFeedEntry: Identifiable, Hashable, Sendable {
    case tasting(TastingFeedItem)
    case memberReview(MemberReviewFeedItem)
    case criticReview(CriticReviewFeedItem)
    case collectionAdd(CollectionAddFeedItem)

    /// Stable across kinds: a tasting and a review can share a numeric ID.
    public var id: String {
        switch self {
        case let .tasting(item): "tasting:\(item.id)"
        case let .memberReview(item): "member-review:\(item.id)"
        case let .criticReview(item): "critic-review:\(item.id)"
        case let .collectionAdd(item): "collection-add:\(item.id)"
        }
    }

    public var createdAt: Date {
        switch self {
        case let .tasting(item): item.createdAt
        case let .memberReview(item): item.createdAt
        case let .criticReview(item): item.createdAt
        case let .collectionAdd(item): item.createdAt
        }
    }

    /// The tasting when this entry is one; toasts and comments only apply to tastings.
    public var tasting: TastingFeedItem? {
        if case let .tasting(item) = self {
            return item
        }
        return nil
    }
}
