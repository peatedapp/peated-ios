import Foundation
@testable import Peated
import PeatedCore
import Testing

@MainActor
struct BlockedUsersModelTests {
    @Test
    func loadsEveryPageNewestFirst() async {
        let repository = BlockingUserRepositoryStub(pages: [
            BlockedUsersPage(users: [blocked("10")], nextCursor: 2),
            BlockedUsersPage(users: [blocked("11")], nextCursor: nil)
        ])
        let model = BlockedUsersModel(repository: repository, blockList: BlockList(store: InMemoryBlockListStore()))

        await model.load()

        #expect(model.state == .loaded([blocked("10"), blocked("11")]))
    }

    @Test
    func unblockingRemovesTheRowAndTheLocalBlock() async {
        let repository = BlockingUserRepositoryStub(pages: [
            BlockedUsersPage(users: [blocked("10"), blocked("11")], nextCursor: nil)
        ])
        let store = InMemoryBlockListStore(ids: ["10", "11"])
        let blockList = BlockList(store: store)
        let model = BlockedUsersModel(repository: repository, blockList: blockList)
        await model.load()

        await model.unblock(blocked("10"))

        let unblockedUserIds = await repository.unblockedUserIds
        #expect(model.state == .loaded([blocked("11")]))
        #expect(blockList.blockedUserIds == ["11"])
        #expect(unblockedUserIds == ["10"])
    }

    @Test
    func reportsAFailedLoad() async {
        let model = BlockedUsersModel(
            repository: BlockingUserRepositoryStub(failsListing: true),
            blockList: BlockList(store: InMemoryBlockListStore())
        )

        await model.load()

        #expect(model.state == .error("Couldn't load your blocked members."))
    }

    private func blocked(_ id: String) -> BlockedUser {
        BlockedUser(user: User(id: id, email: "", username: "member\(id)"), blockedAt: Date(timeIntervalSince1970: 0))
    }
}

/// Keeps blocked IDs in memory so tests never touch user defaults.
final class InMemoryBlockListStore: BlockListStore, @unchecked Sendable {
    private(set) var savedIds: Set<String>

    init(ids: Set<String> = []) {
        savedIds = ids
    }

    func loadBlockedUserIds() -> Set<String> {
        savedIds
    }

    func saveBlockedUserIds(_ ids: Set<String>) {
        savedIds = ids
    }
}

/// A user repository whose block list is fixed up front.
actor BlockingUserRepositoryStub: UserRepositoryProtocol {
    private let pages: [BlockedUsersPage]
    private let failsListing: Bool
    private(set) var unblockedUserIds: [String] = []

    init(pages: [BlockedUsersPage] = [], failsListing: Bool = false) {
        self.pages = pages
        self.failsListing = failsListing
    }

    func getCurrentUser() async throws -> User {
        User(id: "1", email: "", username: "current")
    }

    func getUser(id: String) async throws -> User {
        User(id: id, email: "", username: "member")
    }

    func updateProfile(_: UpdateProfileInput) async throws -> User {
        try await getCurrentUser()
    }

    func followUser(id _: String) async throws {}

    func unfollowUser(id _: String) async throws {}

    func requestAccountDeletion(appleAuthorizationCode _: String?) async throws -> User {
        try await getCurrentUser()
    }

    func cancelAccountDeletion() async throws -> User {
        try await getCurrentUser()
    }

    func blockUser(id _: String) async throws {}

    func unblockUser(id: String) async throws {
        unblockedUserIds.append(id)
    }

    func listBlockedUsers(cursor: Int, limit _: Int) async throws -> BlockedUsersPage {
        if failsListing {
            throw StubError.failed
        }
        let index = cursor - 1
        guard pages.indices.contains(index) else {
            return BlockedUsersPage(users: [], nextCursor: nil)
        }
        return pages[index]
    }

    private enum StubError: Error {
        case failed
    }
}
