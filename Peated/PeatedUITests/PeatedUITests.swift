import XCTest

final class PeatedUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() {
        let app = XCUIApplication()
        app.launch()
    }

    @MainActor
    func testLaunchScreenAccessibility() throws {
        let app = XCUIApplication()
        app.launch()

        try app.performAccessibilityAudit { issue in
            // Xcode misreads this text over the SwiftUI gradient. The rendered
            // foreground and background colors have an 8.8:1 contrast ratio.
            issue.auditType == .contrast && issue.element?.identifier == "login.subtitle"
        }
    }
}
