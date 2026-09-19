import Foundation

/// Remembers which feed the member looked at last so the app reopens on it.
public protocol FeedSelectionStore {
    func loadSelection() -> FeedType?
    func saveSelection(_ type: FeedType)
}

public struct UserDefaultsFeedSelectionStore: FeedSelectionStore {
    private let defaults: UserDefaults
    private let key = "feed.selectedType"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func loadSelection() -> FeedType? {
        defaults.string(forKey: key).flatMap(FeedType.init(rawValue:))
    }

    public func saveSelection(_ type: FeedType) {
        defaults.set(type.rawValue, forKey: key)
    }
}
