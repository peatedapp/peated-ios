import XCTest

/// The signed-in tab bar and Activity feed.
@MainActor
struct HomeScreen {
    let app: XCUIApplication

    var tabBar: XCUIElement {
        app.tabBars.firstMatch
    }

    var activityTab: XCUIElement {
        tabBar.buttons["Activity"]
    }

    var recordTab: XCUIElement {
        tabBar.buttons["Record"]
    }

    @discardableResult
    func waitUntilShown(file: StaticString = #filePath, line: UInt = #line) -> HomeScreen {
        activityTab.expectToAppear(timeout: 20, "Expected the signed-in tab bar", file: file, line: line)
        return self
    }

    func openRecordTasting(file: StaticString = #filePath, line: UInt = #line) -> CreateTastingScreen {
        let sheet = CreateTastingScreen(app: app)
        recordTab.expectToAppear(file: file, line: line).tap()
        // The CI simulator sometimes stalls for seconds right after a relaunch,
        // and the tap synthesized during the stall is lost. One more tap keeps
        // the journey deterministic; a real regression fails both.
        if !sheet.title.waitForExistence(timeout: 10), recordTab.isHittable {
            recordTab.tap()
        }
        return sheet.waitUntilShown(file: file, line: line)
    }

    /// Any feed text mentioning the bottle, such as its name in a tasting card.
    func feedEntry(mentioning text: String) -> XCUIElement {
        app.staticTexts.withLabelContaining(text).firstMatch
    }
}
