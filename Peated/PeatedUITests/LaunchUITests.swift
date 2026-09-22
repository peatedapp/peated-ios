import XCTest

final class LaunchUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testSignedOutLaunchShowsSignIn() {
        let app = AppLaunch.launch(session: .signedOut, stubs: [])

        LoginScreen(app: app).waitUntilShown()
    }

    @MainActor
    func testSignInScreenPassesAccessibilityAudit() throws {
        let app = AppLaunch.launch(session: .signedOut, stubs: [])
        LoginScreen(app: app).waitUntilShown()

        try app.auditAccessibility()
    }
}
