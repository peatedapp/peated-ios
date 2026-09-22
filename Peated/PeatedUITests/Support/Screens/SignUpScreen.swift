import XCTest

/// The Create account form.
struct SignUpScreen {
    let app: XCUIApplication

    var title: XCUIElement {
        app.navigationBars["Create account"]
    }

    var usernameField: XCUIElement {
        app.textFields[AccessibilityID.Auth.username]
    }

    var emailField: XCUIElement {
        app.textFields[AccessibilityID.Auth.email]
    }

    var passwordField: XCUIElement {
        app.secureTextFields[AccessibilityID.Auth.password]
    }

    var termsToggle: XCUIElement {
        app.switches[AccessibilityID.Auth.termsToggle]
    }

    var termsLink: XCUIElement {
        app.buttons[AccessibilityID.Auth.termsLink]
    }

    var privacyLink: XCUIElement {
        app.buttons[AccessibilityID.Auth.privacyLink]
    }

    var createAccountButton: XCUIElement {
        app.buttons[AccessibilityID.Auth.createAccount]
    }

    var failureAlert: XCUIElement {
        app.alerts["Sign Up Failed"]
    }

    @discardableResult
    func waitUntilShown(file: StaticString = #filePath, line: UInt = #line) -> SignUpScreen {
        title.expectToAppear("Expected the Create account screen", file: file, line: line)
        return self
    }

    func fill(username: String, email: String, password: String) {
        usernameField.expectToAppear().enter(username)
        emailField.enter(email)
        passwordField.enter(password)
        // Return ends editing and closes the keyboard so the consent row is reachable.
        passwordField.typeText("\n")
    }

    func acceptTerms() {
        termsToggle.expectToAppear().tap()
    }

    func submit() {
        createAccountButton.expectToAppear().tap()
    }

    /// Asserts the failure alert shows the server's exact explanation.
    func expectFailure(message: String, file: StaticString = #filePath, line: UInt = #line) {
        failureAlert.expectToAppear("Expected the sign-up failure alert", file: file, line: line)
        failureAlert.staticTexts[message].expectToAppear(
            timeout: 2, "Expected the alert to say: \(message)", file: file, line: line
        )
    }

    func dismissFailure() {
        failureAlert.buttons["OK"].tap()
        failureAlert.expectToDisappear()
    }
}
