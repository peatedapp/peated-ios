@testable import PeatedCore

/// Keeps the remembered feed in memory so tests never touch user defaults.
public final class InMemoryFeedSelectionStore: FeedSelectionStore {
    public private(set) var selection: FeedType?

    public init(selection: FeedType? = nil) {
        self.selection = selection
    }

    public func loadSelection() -> FeedType? {
        selection
    }

    public func saveSelection(_ type: FeedType) {
        selection = type
    }
}
