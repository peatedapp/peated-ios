import XCTest

final class PeatedUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testLaunch() {
        let app = XCUIApplication()
        app.launch()
    }

    func testLaunchScreenAccessibility() throws {
        let app = XCUIApplication()
        app.launch()

        try app.performAccessibilityAudit()
    }
}
