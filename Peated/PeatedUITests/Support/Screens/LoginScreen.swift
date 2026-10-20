import XCTest

/// The signed-out landing screen.
@MainActor
struct LoginScreen {
    let app: XCUIApplication

    var continueWithEmailButton: XCUIElement {
        app.buttons["Continue with email"]
    }

    var signUpLink: XCUIElement {
        app.buttons[AccessibilityID.Auth.signUpLink]
    }

    @discardableResult
    func waitUntilShown(file: StaticString = #filePath, line: UInt = #line) -> LoginScreen {
        // The first screen waits on the session check, which is slow on a cold simulator.
        continueWithEmailButton.expectToAppear(timeout: 20, "Expected the sign-in screen", file: file, line: line)
        return self
    }

    var emailSignInButton: XCUIElement {
        app.buttons["Sign in"]
    }

    var otherWaysButton: XCUIElement {
        app.buttons["Other ways to sign in"]
    }

    func openEmailSignIn() {
        continueWithEmailButton.expectToAppear().tap()
        emailSignInButton.expectToAppear("Expected the email sign-in step")
    }

    /// The email step focuses the email field. Return ends editing and closes
    /// the keyboard, which would otherwise cover the form during an audit.
    func dismissKeyboard() {
        app.textFields.firstMatch.typeText("\n")
        app.keyboards.firstMatch.expectToDisappear()
    }

    func openSignUp() -> SignUpScreen {
        signUpLink.expectToAppear().tap()
        return SignUpScreen(app: app).waitUntilShown()
    }
}
