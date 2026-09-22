import Foundation
import Observation

/// Persists the IDs of members the signed-in user has blocked.
public protocol BlockListStore {
    func loadBlockedUserIds() -> Set<String>
    func saveBlockedUserIds(_ ids: Set<String>)
}

public struct UserDefaultsBlockListStore: BlockListStore {
    private let defaults: UserDefaults
    private let key = "blockList.userIds"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func loadBlockedUserIds() -> Set<String> {
        Set(defaults.stringArray(forKey: key) ?? [])
    }

    public func saveBlockedUserIds(_ ids: Set<String>) {
        defaults.set(ids.sorted(), forKey: key)
    }
}

/// The members the signed-in user has blocked, kept on the device so feeds,
/// search, and comments hide their content before the next server fetch.
///
/// The server keeps the list; `refresh(using:)` replaces the local copy with
/// it. Block and unblock update the local copy right away. The list belongs
/// to one account, so it is cleared on sign-out.
@Observable
@MainActor
public final class BlockList {
    public static let shared = BlockList()

    public private(set) var blockedUserIds: Set<String>

    private let store: any BlockListStore

    public init(store: any BlockListStore = UserDefaultsBlockListStore()) {
        self.store = store
        blockedUserIds = store.loadBlockedUserIds()
    }

    public func contains(_ userId: String) -> Bool {
        blockedUserIds.contains(userId)
    }

    public func add(_ userId: String) {
        guard blockedUserIds.insert(userId).inserted else { return }
        store.saveBlockedUserIds(blockedUserIds)
    }

    public func remove(_ userId: String) {
        guard blockedUserIds.remove(userId) != nil else { return }
        store.saveBlockedUserIds(blockedUserIds)
    }

    public func clear() {
        blockedUserIds = []
        store.saveBlockedUserIds(blockedUserIds)
    }

    /// Replaces the local list with the server's. A failed page keeps the local list unchanged.
    public func refresh(using repository: any UserRepositoryProtocol) async {
        var ids: Set<String> = []
        var cursor: Int? = 1
        do {
            // Bounded so a runaway cursor cannot loop forever.
            for _ in 0 ..< 20 {
                guard let page = cursor else { break }
                let result = try await repository.listBlockedUsers(cursor: page, limit: 100)
                ids.formUnion(result.users.map(\.id))
                cursor = result.nextCursor
            }
        } catch {
            Telemetry.capture(error, feature: "block_list", operation: "refresh")
            return
        }
        blockedUserIds = ids
        store.saveBlockedUserIds(ids)
    }
}
