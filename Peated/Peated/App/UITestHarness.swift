#if DEBUG
    import Foundation
    import PeatedCore

    /// Puts the app into the state a UI test asked for.
    ///
    /// UI tests drive the app as a separate process, so they describe the
    /// starting state in the launch environment: which session to start in and
    /// which canned API responses to serve. `PeatedUITests/Support/AppLaunch.swift`
    /// builds those values and is the other half of this contract.
    enum UITestHarness {
        static let launchArgument = "--ui-testing"
        static let sessionKey = "PEATED_UI_TEST_SESSION"
        static let stubsKey = "PEATED_UI_TEST_STUBS"
        static let signedInSession = "signedIn"

        static var isActive: Bool {
            ProcessInfo.processInfo.arguments.contains(launchArgument)
        }

        /// Call before anything touches `APIClient.shared`.
        static func installIfActive() {
            guard isActive else { return }
            let environment = ProcessInfo.processInfo.environment
            resetSession(signedIn: environment[sessionKey] == signedInSession)
            APIClient.launchTransport = StubAPITransport(decodeStubs(environment[stubsKey]))
        }

        /// Every UI test starts from a known session. Signed-in tests get a
        /// placeholder token; the stub transport never checks it.
        private static func resetSession(signedIn: Bool) {
            let keychain = KeychainService.shared
            try? keychain.deleteToken()
            try? keychain.deleteRefreshToken()
            if signedIn {
                try? keychain.saveToken("ui-test-session-token")
            }
        }

        /// Decodes `[{"operation": "getMe", "responses": [{"status": 200, "body": {…}}]}]`.
        private static func decodeStubs(_ json: String?) -> [String: [StubAPITransport.Response]] {
            guard let json,
                  let entries = try? JSONSerialization.jsonObject(with: Data(json.utf8)) as? [[String: Any]]
            else { return [:] }

            var table: [String: [StubAPITransport.Response]] = [:]
            for entry in entries {
                guard let operation = entry["operation"] as? String,
                      let responses = entry["responses"] as? [[String: Any]]
                else { continue }
                table[operation] = responses.map { response in
                    let status = response["status"] as? Int ?? 200
                    let body = response["body"].flatMap { try? JSONSerialization.data(withJSONObject: $0) }
                    return StubAPITransport.Response(status: status, body: body ?? Data())
                }
            }
            return table
        }
    }
#endif
