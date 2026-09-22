import Foundation
@testable import PeatedCore
import Testing

/// Sign-up must show the server's reason for refusing an account, not a generic
/// decoding failure. The generated contract omits the 409 conflict the server
/// uses for a taken username, so both documented and undocumented failures are covered.
struct AuthenticationManagerRegisterTests {
    @Test
    func takenUsernameSurfacesServerMessage() async throws {
        let transport = StubAPITransport([
            "register": [.json(409, Self.serverError(409, "CONFLICT", "An account with this username already exists."))]
        ])
        let manager = makeManager(transport: transport)

        await #expect(throws: AuthError.registrationRejected("An account with this username already exists.")) {
            try await manager.register(username: "taken", email: "new@example.com", password: "correct horse")
        }
        #expect(manager.authState == .unauthenticated)
    }

    @Test
    func rejectedPasswordSurfacesServerMessage() async throws {
        let transport = StubAPITransport([
            "register": [.json(400, Self.serverError(400, "BAD_REQUEST", "Password must be at least 8 characters."))]
        ])
        let manager = makeManager(transport: transport)

        await #expect(throws: AuthError.registrationRejected("Password must be at least 8 characters.")) {
            try await manager.register(username: "newmember", email: "new@example.com", password: "short")
        }
    }

    @Test
    func undocumentedFailureWithoutMessageFallsBackToGenericError() async throws {
        let transport = StubAPITransport([
            "register": [.json(418, "{}")]
        ])
        let manager = makeManager(transport: transport)

        await #expect(throws: AuthError.registrationRejected("Invalid response from server")) {
            try await manager.register(username: "newmember", email: "new@example.com", password: "correct horse")
        }
    }

    /// The error body the Peated API sends for every refused request.
    private static func serverError(_ status: Int, _ code: String, _ message: String) -> String {
        #"{"defined":true,"code":"\#(code)","status":\#(status),"message":"\#(message)","data":{}}"#
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
