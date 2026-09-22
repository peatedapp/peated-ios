import XCTest

/// The API answers 403 "Terms acceptance required" until the member accepts
/// updated terms. The app must block on that answer and carry on afterwards.
final class TermsAcceptanceUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testBlocksUntilTermsAcceptedThenAllowsRecordingATasting() throws {
        let stubs = [APIStub].signedInBaseline() + [APIStub].createTasting() + [
            // The first feed load is refused; after acceptance the feed loads.
            .sequence("listActivity", [
                .failure(403, Fixtures.termsAcceptanceRequired),
                .ok(Fixtures.activity(tastings: []))
            ]),
            .ok("acceptTos", Fixtures.user())
        ]
        let app = AppLaunch.launch(session: .signedIn, stubs: stubs, resetting: [.location])

        let terms = TermsScreen(app: app).waitUntilShown()
        try app.performAccessibilityAudit()

        terms.accept()
        terms.title.expectToDisappear("Accepting the terms must dismiss the gate")

        let home = HomeScreen(app: app).waitUntilShown()
        home.openRecordTasting().recordTasting(bottleNamed: Fixtures.bottleName)
    }
}
