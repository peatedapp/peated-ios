import XCTest

/// The full-screen Terms of Service acceptance gate.
@MainActor
struct TermsScreen {
    let app: XCUIApplication

    var title: XCUIElement {
        app.staticTexts["Terms of Service Update"]
    }

    var acceptButton: XCUIElement {
        app.buttons[AccessibilityID.Terms.accept]
    }

    @discardableResult
    func waitUntilShown(file: StaticString = #filePath, line: UInt = #line) -> TermsScreen {
        title.expectToAppear(timeout: 20, "Expected the terms acceptance screen", file: file, line: line)
            .waitUntilStill()
        return self
    }

    func accept() {
        acceptButton.expectToAppear().tap()
    }
}
