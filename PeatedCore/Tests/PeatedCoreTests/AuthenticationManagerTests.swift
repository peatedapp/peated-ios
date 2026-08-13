import Foundation
@testable import PeatedCore
import Testing

struct AuthenticationManagerTests {
    private let apiServerURLString = "https://api.peated.com/v1"

    @Test
    func logoutSignsOutGoogleAndClearsLocalState() async throws {
        let signOutSpy = SignOutSpy()
        let manager = try AuthenticationManager(
            apiClient: APIClient(serverURL: #require(URL(string: apiServerURLString))),
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
            apiClient: APIClient(serverURL: #require(URL(string: apiServerURLString))),
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
}

private final class SignOutSpy: @unchecked Sendable {
    var callCount = 0
}

private struct LogoutFailure: Error {}
