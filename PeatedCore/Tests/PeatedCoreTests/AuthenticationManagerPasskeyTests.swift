import Foundation
@testable import PeatedCore
import Testing

/// Passkey sign-in turns the server's base64url challenge into bytes for the
/// system sheet, then trades the signed assertion for a session.
@MainActor
struct AuthenticationManagerPasskeyTests {
    /// `-_8B` is base64url for bytes that need the URL-safe alphabet and no padding.
    private static let challengeJSON = #"""
    {"signedChallenge":"signed-challenge","options":{"challenge":"-_8B","rpId":"peated.com",
     "userVerification":"preferred","allowCredentials":[{"id":"AQID","type":"public-key"}]}}
    """#
    /// No access token, so the test never writes to the real keychain.
    private static let authJSON = #"{"user":{"id":7,"username":"passkeymember"}}"#

    private static let assertion = PasskeyAssertion(
        credentialID: Data([1, 2, 3]),
        clientDataJSON: Data("{}".utf8),
        authenticatorData: Data([4, 5]),
        signature: Data([6]),
        userHandle: nil
    )

    @Test
    func signsInWithTheDecodedChallenge() async throws {
        let transport = StubAPITransport([
            "passkeyAuthenticateChallenge": [.json(200, Self.challengeJSON)],
            "passkeyAuthenticateVerify": [.json(200, Self.authJSON)]
        ])
        let manager = makeManager(transport: transport)
        var presented: PasskeySignInChallenge?

        let user = try await manager.loginWithPasskey { challenge in
            presented = challenge
            return Self.assertion
        }

        #expect(presented?.challenge == Data([0xFB, 0xFF, 0x01]))
        #expect(presented?.relyingPartyID == "peated.com")
        #expect(presented?.allowedCredentialIDs == [Data([1, 2, 3])])
        #expect(presented?.userVerification == "preferred")
        #expect(user?.username == "passkeymember")
        try #expect(manager.authState == .authenticated(#require(user)))
        #expect(manager.signInProvider == .passkey)
    }

    @Test
    func cancellingTheSheetLeavesTheUserSignedOut() async throws {
        let transport = StubAPITransport([
            "passkeyAuthenticateChallenge": [.json(200, Self.challengeJSON)]
        ])
        let manager = makeManager(transport: transport)

        let user = try await manager.loginWithPasskey { _ in nil }

        #expect(user == nil)
        #expect(!manager.isAuthenticated)
        #expect(transport.unstubbedOperations.isEmpty, "A cancelled sheet must not send an assertion")
    }

    @Test
    func refusedAssertionFailsTheSignIn() async throws {
        let transport = StubAPITransport([
            "passkeyAuthenticateChallenge": [.json(200, Self.challengeJSON)],
            "passkeyAuthenticateVerify": [.json(401, #"{"message":"Unknown passkey"}"#)]
        ])
        let manager = makeManager(transport: transport)

        await #expect(throws: (any Error).self) {
            try await manager.loginWithPasskey { _ in Self.assertion }
        }
        #expect(manager.authState == .unauthenticated)
    }

    private func makeManager(transport: StubAPITransport) -> AuthenticationManager {
        AuthenticationManager(
            apiClient: APIClient(transport: transport),
            deleteStoredToken: {},
            googleSignOut: {},
            defaults: UserDefaults(suiteName: "AuthenticationManagerPasskeyTests-\(UUID().uuidString)")!
        )
    }
}
