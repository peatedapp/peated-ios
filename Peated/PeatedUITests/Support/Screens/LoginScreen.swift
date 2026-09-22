import XCTest

/// The signed-out landing screen.
struct LoginScreen {
    let app: XCUIApplication

    var signInButton: XCUIElement {
        app.buttons["Sign In"]
    }

    var signUpLink: XCUIElement {
        app.buttons[AccessibilityID.Auth.signUpLink]
    }

    @discardableResult
    func waitUntilShown(file: StaticString = #filePath, line: UInt = #line) -> LoginScreen {
        signInButton.expectToAppear("Expected the sign-in screen", file: file, line: line)
        return self
    }

    func openSignUp() -> SignUpScreen {
        signUpLink.expectToAppear().tap()
        return SignUpScreen(app: app).waitUntilShown()
    }
}
