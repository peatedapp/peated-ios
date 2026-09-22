import Foundation
@testable import PeatedCore

/// A user repository whose block list is fixed up front, for block list and model tests.
actor BlockingUserRepositoryStub: UserRepositoryProtocol {
    private let pages: [BlockedUsersPage]
    private let failsListing: Bool
    private(set) var blockedUserIds: [String] = []
    private(set) var unblockedUserIds: [String] = []
    private(set) var requestedCursors: [Int] = []

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

    func blockUser(id: String) async throws {
        blockedUserIds.append(id)
    }

    func unblockUser(id: String) async throws {
        unblockedUserIds.append(id)
    }

    func listBlockedUsers(cursor: Int, limit _: Int) async throws -> BlockedUsersPage {
        requestedCursors.append(cursor)
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
