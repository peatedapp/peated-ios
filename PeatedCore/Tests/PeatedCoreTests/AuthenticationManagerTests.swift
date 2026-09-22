import Foundation
@testable import PeatedCore
import Testing

struct AuthenticationManagerTests {
    @Test
    func logoutSignsOutGoogleAndClearsLocalState() async throws {
        let signOutSpy = SignOutSpy()
        let manager = try AuthenticationManager(
            apiClient: APIClient(serverURL: #require(URL(string: "https://api.peated.com/v1"))),
            deleteStoredToken: {},
            googleSignOut: {
                signOutSpy.callCount += 1
            }
        )

        manager.needsTermsAcceptance = true
        manager.error = LogoutFailure()

        await manager.logout()

        #expect(signOutSpy.callCount == 1)
        #expect(manager.authState == .unauthenticated)
        #expect(manager.needsTermsAcceptance == false)
        #expect(manager.isLoading == false)

        if manager.error != nil {
            Issue.record("Expected logout to clear any previous error state")
        }
    }

    @Test
    func logoutStillSignsOutGoogleWhenTokenDeletionFails() async throws {
        let signOutSpy = SignOutSpy()
        let manager = try AuthenticationManager(
            apiClient: APIClient(serverURL: #require(URL(string: "https://api.peated.com/v1"))),
            deleteStoredToken: {
                throw LogoutFailure()
            },
            googleSignOut: {
                signOutSpy.callCount += 1
            }
        )

        manager.needsTermsAcceptance = true

        await manager.logout()

        #expect(signOutSpy.callCount == 1)
        #expect(manager.authState == .unauthenticated)
        #expect(manager.needsTermsAcceptance == false)
        #expect(manager.isLoading == false)

        if let error = manager.error {
            #expect(error is LogoutFailure)
        } else {
            Issue.record("Expected logout to surface the token deletion error")
        }
    }

    @Test
    func logoutClearsSignInProvider() async throws {
        let suiteName = "AuthenticationManagerTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set("apple", forKey: "com.peated.signInProvider")
        let manager = try makeManager(repository: UserRepositoryStub(user: nil), defaults: defaults)

        #expect(manager.signInProvider == .apple)

        await manager.logout()

        #expect(manager.signInProvider == nil)
    }

    @Test
    func requestAccountDeletionStoresScheduledDateOnCurrentUser() async throws {
        let scheduledAt = Date(timeIntervalSince1970: 1_800_000_000)
        var scheduledUser = User(id: "1", email: "jane@example.com", username: "jane")
        scheduledUser.deletionScheduledAt = scheduledAt
        let repository = UserRepositoryStub(user: scheduledUser)
        let manager = try makeManager(repository: repository)

        try await manager.requestAccountDeletion(appleAuthorizationCode: "apple-code")

        let sentCodes = await repository.appleAuthorizationCodes
        #expect(manager.currentUser?.deletionScheduledAt == scheduledAt)
        #expect(sentCodes == ["apple-code"])
    }

    @Test
    func cancelAccountDeletionClearsScheduledDate() async throws {
        let keptUser = User(id: "1", email: "jane@example.com", username: "jane")
        let repository = UserRepositoryStub(user: keptUser)
        let manager = try makeManager(repository: repository)

        try await manager.cancelAccountDeletion()

        let cancellations = await repository.cancellationCount
        #expect(manager.currentUser == keptUser)
        #expect(manager.currentUser?.deletionScheduledAt == nil)
        #expect(cancellations == 1)
    }

    @Test
    func requestAccountDeletionLeavesSessionAloneWhenRequestFails() async throws {
        let repository = UserRepositoryStub(user: nil)
        let manager = try makeManager(repository: repository)

        await #expect(throws: DeletionFailure.self) {
            try await manager.requestAccountDeletion(appleAuthorizationCode: nil)
        }

        #expect(manager.authState == .unknown)
    }

    private func makeManager(
        repository: UserRepositoryStub,
        defaults: UserDefaults = .standard
    ) throws -> AuthenticationManager {
        try AuthenticationManager(
            apiClient: APIClient(serverURL: #require(URL(string: "https://api.peated.com/v1"))),
            userRepository: repository,
            deleteStoredToken: {},
            googleSignOut: {},
            defaults: defaults
        )
    }
}

private final class SignOutSpy: @unchecked Sendable {
    var callCount = 0
}

private struct LogoutFailure: Error {}

private struct DeletionFailure: Error {}

/// Returns `user` from the deletion calls, or throws when there is none.
private actor UserRepositoryStub: UserRepositoryProtocol {
    private let user: User?
    private(set) var appleAuthorizationCodes: [String?] = []
    private(set) var cancellationCount = 0

    init(user: User?) {
        self.user = user
    }

    func getCurrentUser() async throws -> User {
        try result()
    }

    func getUser(id _: String) async throws -> User {
        try result()
    }

    func updateProfile(_: UpdateProfileInput) async throws -> User {
        try result()
    }

    func followUser(id _: String) async throws {}

    func unfollowUser(id _: String) async throws {}

    func requestAccountDeletion(appleAuthorizationCode: String?) async throws -> User {
        appleAuthorizationCodes.append(appleAuthorizationCode)
        return try result()
    }

    func cancelAccountDeletion() async throws -> User {
        cancellationCount += 1
        return try result()
    }

    private func result() throws -> User {
        guard let user else { throw DeletionFailure() }
        return user
    }
}
