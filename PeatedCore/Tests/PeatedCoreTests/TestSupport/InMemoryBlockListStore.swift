@testable import PeatedCore

/// Keeps blocked IDs in memory so tests never touch user defaults.
public final class InMemoryBlockListStore: BlockListStore, @unchecked Sendable {
    public private(set) var savedIds: Set<String>

    public init(ids: Set<String> = []) {
        savedIds = ids
    }

    public func loadBlockedUserIds() -> Set<String> {
        savedIds
    }

    public func saveBlockedUserIds(_ ids: Set<String>) {
        savedIds = ids
    }
}
