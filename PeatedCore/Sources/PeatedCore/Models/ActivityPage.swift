import Foundation

/// One page of the activity feed. The cursor is opaque; pass it back unchanged.
public struct ActivityPage: Sendable {
    public let entries: [ActivityFeedEntry]
    public let cursor: String?
    public let hasMore: Bool

    public init(entries: [ActivityFeedEntry], cursor: String?, hasMore: Bool) {
        self.entries = entries
        self.cursor = cursor
        self.hasMore = hasMore
    }
}
