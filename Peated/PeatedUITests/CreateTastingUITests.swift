import XCTest

/// Recording a tasting is the app's core write path.
final class CreateTastingUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testRecordsTastingAndShowsItInActivity() throws {
        let tasting = Fixtures.tasting()
        let stubs = [APIStub].signedInBaseline() + [APIStub].createTasting() + [
            // Empty before the tasting is saved; the refresh afterwards shows it.
            .sequence("listActivity", [
                .ok(Fixtures.activity(tastings: [])),
                .ok(Fixtures.activity(tastings: [tasting]))
            ])
        ]
        let app = AppLaunch.launch(session: .signedIn, stubs: stubs, resetting: [.location])

        let home = HomeScreen(app: app).waitUntilShown()
        let flow = home.openRecordTasting()
        try app.performAccessibilityAudit()

        flow.recordTasting(bottleNamed: Fixtures.bottleName)

        home.feedEntry(mentioning: Fixtures.bottleName)
            .expectToAppear(timeout: 15, "Expected the new tasting in the Activity feed")
    }

    @MainActor
    func testContinueWaitsForABottle() {
        let stubs = [APIStub].signedInBaseline() + [APIStub].createTasting()
        let app = AppLaunch.launch(session: .signedIn, stubs: stubs)

        let flow = HomeScreen(app: app).waitUntilShown().openRecordTasting()

        XCTAssertFalse(flow.continueButton.isEnabled, "A tasting needs a bottle before anything else")
        flow.selectBottle(named: Fixtures.bottleName)
        XCTAssertTrue(flow.continueButton.isEnabled)
    }
}
