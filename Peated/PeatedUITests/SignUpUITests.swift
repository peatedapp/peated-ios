import XCTest

/// Sign-up is the first thing App Review does. These journeys cover the
/// happy path, the consent gate, and the two refusals the server sends.
final class SignUpUITests: XCTestCase {
    private let username = "newmember"
    private let email = "newmember@example.com"
    private let password = "correct-horse-battery"

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCreatesAccountAndLandsOnActivity() throws {
        let stubs: [APIStub] = [
            .ok("register", Fixtures.auth(user: Fixtures.user(username: username))),
            .ok("getUser", Fixtures.userProfile(username: username)),
            .ok("listActivity", Fixtures.activity(tastings: [])),
            .ok("countNotifications", #"{"count":0}"#)
        ]
        let app = AppLaunch.launch(session: .signedOut, stubs: stubs)

        let signUp = LoginScreen(app: app).waitUntilShown().openSignUp()
        try app.performAccessibilityAudit()

        signUp.fill(username: username, email: email, password: password)
        signUp.acceptTerms()
        signUp.submit()

        HomeScreen(app: app).waitUntilShown()
    }

    @MainActor
    func testCreateAccountRequiresTermsAndPrivacyConsent() {
        let app = AppLaunch.launch(session: .signedOut, stubs: [])
        let signUp = LoginScreen(app: app).waitUntilShown().openSignUp()

        signUp.fill(username: username, email: email, password: password)

        XCTAssertTrue(signUp.termsLink.exists, "The consent row must link to the Terms of Service")
        XCTAssertTrue(signUp.privacyLink.exists, "The consent row must link to the Privacy Policy")
        XCTAssertFalse(signUp.createAccountButton.isEnabled, "Sign-up must wait for consent")

        signUp.acceptTerms()

        XCTAssertTrue(signUp.createAccountButton.isEnabled, "Consent unlocks sign-up")
    }

    @MainActor
    func testTakenUsernameShowsServerMessage() {
        let message = "An account with this username already exists."
        let stubs: [APIStub] = [
            .failure("register", 409, Fixtures.serverError(status: 409, code: "CONFLICT", message: message))
        ]
        let app = AppLaunch.launch(session: .signedOut, stubs: stubs)
        let signUp = LoginScreen(app: app).waitUntilShown().openSignUp()

        signUp.fill(username: "taken", email: email, password: password)
        signUp.acceptTerms()
        signUp.submit()

        signUp.expectFailure(message: message)
        signUp.dismissFailure()
        signUp.waitUntilShown()
        XCTAssertTrue(signUp.createAccountButton.isEnabled, "The form stays editable after a refusal")
    }

    @MainActor
    func testRejectedPasswordShowsServerMessage() {
        let message = "Password must be at least 8 characters."
        let stubs: [APIStub] = [
            .failure("register", 400, Fixtures.serverError(status: 400, code: "BAD_REQUEST", message: message))
        ]
        let app = AppLaunch.launch(session: .signedOut, stubs: stubs)
        let signUp = LoginScreen(app: app).waitUntilShown().openSignUp()

        signUp.fill(username: username, email: email, password: "short")
        signUp.acceptTerms()
        signUp.submit()

        signUp.expectFailure(message: message)
    }
}
