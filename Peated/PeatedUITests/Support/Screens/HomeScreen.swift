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

    func openRecordTasting() -> CreateTastingScreen {
        recordTab.expectToAppear().tap()
        return CreateTastingScreen(app: app).waitUntilShown()
    }

    /// Any feed text mentioning the bottle, such as its name in a tasting card.
    func feedEntry(mentioning text: String) -> XCUIElement {
        app.staticTexts.withLabelContaining(text).firstMatch
    }
}
