@testable import Peated
import PeatedCore
import Testing

@MainActor
struct SearchFriendshipTests {
    @Test
    func followsUserOptimistically() async {
        let repository = UserRepositoryStub()
        let model = SearchModel(userRepository: repository, loadsPopularContent: false)
        let result = userResult(status: .none)
        model.state = .results([result])

        await model.toggleFriendship(for: result)

        let followedUserIds = await repository.followedUserIds
        #expect(friendStatus(in: model) == .pending)
        #expect(followedUserIds == [result.id])
        #expect(model.updatingFriendIds.isEmpty)
    }

    @Test
    func unfollowsExistingFriend() async {
        let repository = UserRepositoryStub()
        let model = SearchModel(userRepository: repository, loadsPopularContent: false)
        let result = userResult(status: .friends)
        model.state = .results([result])

        await model.toggleFriendship(for: result)

        let unfollowedUserIds = await repository.unfollowedUserIds
        #expect(friendStatus(in: model) == User.FriendStatus.none)
        #expect(unfollowedUserIds == [result.id])
    }

    @Test
    func rollsBackFailedFriendshipUpdate() async {
        let repository = UserRepositoryStub(shouldFail: true)
        let model = SearchModel(userRepository: repository, loadsPopularContent: false)
        let result = userResult(status: .none)
        model.state = .results([result])

        await model.toggleFriendship(for: result)

        #expect(friendStatus(in: model) == User.FriendStatus.none)
        #expect(model.friendshipErrorMessage != nil)
        #expect(model.updatingFriendIds.isEmpty)
    }

    private func userResult(status: User.FriendStatus) -> SearchResult {
        SearchResult(
            id: "42",
            type: .user,
            name: "friend",
            friendStatus: status
        )
    }

    private func friendStatus(in model: SearchModel) -> User.FriendStatus? {
        guard case let .results(results) = model.state else { return nil }
        return results.first?.friendStatus
    }
}

private actor UserRepositoryStub: UserRepositoryProtocol {
    private(set) var followedUserIds: [String] = []
    private(set) var unfollowedUserIds: [String] = []
    private let shouldFail: Bool

    init(shouldFail: Bool = false) {
        self.shouldFail = shouldFail
    }

    func getCurrentUser() async throws -> User {
        User(id: "1", email: "", username: "current")
    }

    func getUser(id: String) async throws -> User {
        User(id: id, email: "", username: "friend")
    }

    func updateProfile(_: UpdateProfileInput) async throws -> User {
        try await getCurrentUser()
    }

    func followUser(id: String) async throws {
        if shouldFail {
            throw StubError.failed
        }
        followedUserIds.append(id)
    }

    func unfollowUser(id: String) async throws {
        if shouldFail {
            throw StubError.failed
        }
        unfollowedUserIds.append(id)
    }

    private enum StubError: Error {
        case failed
    }
}
