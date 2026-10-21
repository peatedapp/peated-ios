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

    /// The audit is the last step. On a loaded CI runner, the first tap after
    /// this audit has been lost inside the simulator: backboardd registered
    /// XCTest's virtual touch digitizer twice, dropped the touch-up, and the
    /// app saw the touch cancelled. No tap follows the audit here.
    @MainActor
    func testEmailSignInStepPassesAccessibilityAudit() throws {
        let app = AppLaunch.launch(session: .signedOut, stubs: [])
        let login = LoginScreen(app: app).waitUntilShown()

        login.openEmailSignIn()
        login.dismissKeyboard()
        try app.auditAccessibility()
    }

    @MainActor
    func testEmailSignInStepShowsPasswordFormAndReturns() {
        let app = AppLaunch.launch(session: .signedOut, stubs: [])
        let login = LoginScreen(app: app).waitUntilShown()

        login.openEmailSignIn()

        login.otherWaysButton.tap()
        login.continueWithEmailButton.expectToAppear("Expected the sign-in methods")
    }
}
