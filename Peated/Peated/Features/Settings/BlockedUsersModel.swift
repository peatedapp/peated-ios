import Observation
import PeatedCore

/// Loads the signed-in member's block list and removes blocks from it.
@Observable
@MainActor
final class BlockedUsersModel {
    enum State: Equatable {
        case loading
        case loaded([BlockedUser])
        case error(String)
    }

    private(set) var state: State = .loading
    private(set) var unblockingUserIds: Set<String> = []

    private let repository: any UserRepositoryProtocol
    private let blockList: BlockList

    init(repository: any UserRepositoryProtocol = UserRepository(), blockList: BlockList = .shared) {
        self.repository = repository
        self.blockList = blockList
    }

    /// Fetches every page. The server sends newest first and pages are small.
    func load() async {
        state = .loading
        var users: [BlockedUser] = []
        var cursor: Int? = 1
        do {
            while let page = cursor {
                let result = try await repository.listBlockedUsers(cursor: page, limit: 100)
                users.append(contentsOf: result.users)
                cursor = result.nextCursor
            }
        } catch {
            Telemetry.capture(error, feature: "block_list", operation: "load")
            state = .error("Couldn't load your blocked members.")
            return
        }
        state = .loaded(users)
    }

    func unblock(_ blocked: BlockedUser) async {
        guard case let .loaded(users) = state, !unblockingUserIds.contains(blocked.id) else { return }
        unblockingUserIds.insert(blocked.id)
        defer { unblockingUserIds.remove(blocked.id) }
        do {
            try await repository.unblockUser(id: blocked.id)
            blockList.remove(blocked.id)
            state = .loaded(users.filter { $0.id != blocked.id })
            ToastManager.shared.showSuccess("You unblocked @\(blocked.user.username).")
        } catch {
            Telemetry.capture(error, feature: "block_list", operation: "unblock")
            ToastManager.shared.showError("Couldn't unblock @\(blocked.user.username). Try again.")
        }
    }
}
