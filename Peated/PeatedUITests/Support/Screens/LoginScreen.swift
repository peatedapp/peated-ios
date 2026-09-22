import XCTest

/// The signed-out landing screen.
@MainActor
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
        // The first screen waits on the session check, which is slow on a cold simulator.
        signInButton.expectToAppear(timeout: 20, "Expected the sign-in screen", file: file, line: line)
        return self
    }

    func openSignUp() -> SignUpScreen {
        signUpLink.expectToAppear().tap()
        return SignUpScreen(app: app).waitUntilShown()
    }
}
