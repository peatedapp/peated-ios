import Foundation
@testable import PeatedCore
import Testing

/// Sign-up creates the account with a new passkey. A refusal must reach the
/// screen as the server's reason, and a taken email or username must say
/// which field is taken, so the screen can offer to sign in instead.
@MainActor
struct AuthenticationManagerRegisterTests {
    /// `-_8B` and `AQID` are base64url for bytes that need the URL-safe alphabet and no padding.
    private static let challengeJSON = #"""
    {"signedChallenge":"signed-challenge","options":{"challenge":"-_8B","rp":{"id":"peated.com","name":"Peated"},
     "user":{"id":"AQID","name":"newmember","displayName":"newmember"},
     "pubKeyCredParams":[{"alg":-7,"type":"public-key"}],
     "authenticatorSelection":{"userVerification":"preferred"}}}
    """#
    /// No access token, so the test never writes to the real keychain.
    private static let authJSON = #"{"user":{"id":7,"username":"newmember"}}"#

    private static let registration = PasskeyRegistration(
        credentialID: Data([9, 9]),
        clientDataJSON: Data("{}".utf8),
        attestationObject: Data([1])
    )

    @Test
    func createsTheAccountWithTheDecodedChallenge() async throws {
        let transport = StubAPITransport([
            "registerChallenge": [.json(200, Self.challengeJSON)],
            "register": [.json(200, Self.authJSON)]
        ])
        let manager = makeManager(transport: transport)
        var presented: PasskeyRegistrationChallenge?

        let user = try await manager.registerWithPasskey(username: "newmember", email: "new@example.com",
                                                         tosAccepted: true) { challenge in
            presented = challenge
            return Self.registration
        }

        #expect(presented?.challenge == Data([0xFB, 0xFF, 0x01]))
        #expect(presented?.relyingPartyID == "peated.com")
        #expect(presented?.userID == Data([1, 2, 3]))
        #expect(presented?.userName == "newmember")
        #expect(presented?.userVerification == "preferred")
        #expect(user?.username == "newmember")
        #expect(manager.signInProvider == .passkey)
    }

    @Test
    func cancellingTheSheetCreatesNoAccount() async throws {
        let transport = StubAPITransport([
            "registerChallenge": [.json(200, Self.challengeJSON)]
        ])
        let manager = makeManager(transport: transport)

        let user = try await manager.registerWithPasskey(username: "newmember", email: "new@example.com",
                                                         tosAccepted: true) { _ in nil }

        #expect(user == nil)
        #expect(!manager.isAuthenticated)
        #expect(transport.unstubbedOperations.isEmpty, "A cancelled sheet must not call register")
    }

    @Test
    func takenEmailNamesTheField() async throws {
        let transport = StubAPITransport([
            "registerChallenge": [
                .json(409, Self.conflict(field: "email", "An account with this email already exists."))
            ]
        ])
        let manager = makeManager(transport: transport)

        await #expect(throws: AuthError.registrationConflict(field: .email,
                                                             message: "An account with this email already exists.")) {
            try await manager.registerWithPasskey(username: "newmember", email: "taken@example.com",
                                                  tosAccepted: true) { _ in Self.registration }
        }
        #expect(manager.authState == .unauthenticated)
    }

    @Test
    func takenUsernameAtRegisterNamesTheField() async throws {
        let transport = StubAPITransport([
            "registerChallenge": [.json(200, Self.challengeJSON)],
            "register": [.json(409, Self.conflict(field: "username", "That username is taken."))]
        ])
        let manager = makeManager(transport: transport)

        await #expect(throws: AuthError.registrationConflict(field: .username, message: "That username is taken.")) {
            try await manager.registerWithPasskey(username: "taken", email: "new@example.com",
                                                  tosAccepted: true) { _ in Self.registration }
        }
    }

    @Test
    func refusedRegistrationSurfacesServerMessage() async throws {
        let transport = StubAPITransport([
            "registerChallenge": [.json(400, Self.serverError(400, "BAD_REQUEST", "Username must be 3 characters."))]
        ])
        let manager = makeManager(transport: transport)

        await #expect(throws: AuthError.registrationRejected("Username must be 3 characters.")) {
            try await manager.registerWithPasskey(username: "ab", email: "new@example.com",
                                                  tosAccepted: true) { _ in Self.registration }
        }
    }

    @Test
    func undocumentedFailureWithoutMessageFallsBackToGenericError() async throws {
        let transport = StubAPITransport([
            "registerChallenge": [.json(418, "{}")]
        ])
        let manager = makeManager(transport: transport)

        await #expect(throws: AuthError.registrationRejected("Invalid response from server")) {
            try await manager.registerWithPasskey(username: "newmember", email: "new@example.com",
                                                  tosAccepted: true) { _ in Self.registration }
        }
    }

    /// The error body the Peated API sends for every refused request.
    private static func serverError(_ status: Int, _ code: String, _ message: String) -> String {
        #"{"defined":true,"code":"\#(code)","status":\#(status),"message":"\#(message)","data":{}}"#
    }

    private static func conflict(field: String, _ message: String) -> String {
        #"{"defined":true,"code":"CONFLICT","status":409,"message":"\#(message)","data":{"field":"\#(field)"}}"#
    }

    private func makeManager(transport: StubAPITransport) -> AuthenticationManager {
        AuthenticationManager(
            apiClient: APIClient(transport: transport),
            deleteStoredToken: {},
            googleSignOut: {},
            defaults: UserDefaults(suiteName: "AuthenticationManagerRegisterTests-\(UUID().uuidString)")!
        )
    }
}
