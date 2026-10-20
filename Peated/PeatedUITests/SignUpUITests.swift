import XCTest

/// Sign-up is the first thing App Review does. These journeys cover the
/// happy path, the consent gate, and the refusals the server sends.
final class SignUpUITests: XCTestCase {
    private let username = "newmember"
    private let email = "newmember@example.com"

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testCreatesAccountAndLandsOnActivity() throws {
        let stubs: [APIStub] = [
            .ok("registerChallenge", Fixtures.registrationChallenge(username: username)),
            .ok("register", Fixtures.auth(user: Fixtures.user(username: username))),
            .ok("getUser", Fixtures.userProfile(username: username)),
            .ok("listActivity", Fixtures.activity(tastings: [])),
            .ok("countNotifications", #"{"count":0}"#)
        ]
        let app = AppLaunch.launch(session: .signedOut, stubs: stubs)

        let signUp = LoginScreen(app: app).waitUntilShown().openSignUp()
        try app.auditAccessibility()

        signUp.fill(email: email, username: username)
        signUp.acceptTerms()
        signUp.submit()

        HomeScreen(app: app).waitUntilShown()
    }

    @MainActor
    func testCreateAccountRequiresTermsAndPrivacyConsent() {
        let app = AppLaunch.launch(session: .signedOut, stubs: [])
        let signUp = LoginScreen(app: app).waitUntilShown().openSignUp()

        signUp.fill(email: email, username: username)

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
            .failure("registerChallenge", 409, Fixtures.registrationConflict(field: "username", message: message))
        ]
        let app = AppLaunch.launch(session: .signedOut, stubs: stubs)
        let signUp = LoginScreen(app: app).waitUntilShown().openSignUp()

        signUp.fill(email: email, username: "taken")
        signUp.acceptTerms()
        signUp.submit()

        signUp.expectFailure(message: message)
        XCTAssertTrue(signUp.createAccountButton.isEnabled, "The form stays editable after a refusal")
    }

    @MainActor
    func testTakenEmailOffersWaysToSignIn() throws {
        let message = "An account with this email already exists."
        let stubs: [APIStub] = [
            .failure("registerChallenge", 409, Fixtures.registrationConflict(field: "email", message: message))
        ]
        let app = AppLaunch.launch(session: .signedOut, stubs: stubs)
        let signUp = LoginScreen(app: app).waitUntilShown().openSignUp()

        signUp.fill(email: email, username: username)
        signUp.acceptTerms()
        signUp.submit()

        signUp.takenEmailTitle.expectToAppear("Expected the taken email step")
        try app.auditAccessibility()
        app.buttons["Use a different email"].tap()
        signUp.waitUntilShown()
    }

    @MainActor
    func testRejectedSignUpShowsServerMessage() {
        let message = "Username must be at least 3 characters."
        let stubs: [APIStub] = [
            .failure("registerChallenge", 400, Fixtures.serverError(status: 400, code: "BAD_REQUEST", message: message))
        ]
        let app = AppLaunch.launch(session: .signedOut, stubs: stubs)
        let signUp = LoginScreen(app: app).waitUntilShown().openSignUp()

        signUp.fill(email: email, username: "ab")
        signUp.acceptTerms()
        signUp.submit()

        signUp.expectFailure(message: message)
    }
}
