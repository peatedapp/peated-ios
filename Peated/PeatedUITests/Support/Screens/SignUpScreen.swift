import XCTest

/// The Create an account form.
@MainActor
struct SignUpScreen {
    let app: XCUIApplication

    var title: XCUIElement {
        app.staticTexts["Create an account"]
    }

    var emailField: XCUIElement {
        app.textFields[AccessibilityID.Auth.email]
    }

    var usernameField: XCUIElement {
        app.textFields[AccessibilityID.Auth.username]
    }

    /// A checkbox drawn as a button with the toggle trait, so match any element type.
    var termsCheckbox: XCUIElement {
        app.descendants(matching: .any)[AccessibilityID.Auth.termsToggle]
    }

    /// An inline link inside the consent sentence.
    var termsLink: XCUIElement {
        app.links["Terms of Service"]
    }

    var privacyLink: XCUIElement {
        app.links["Privacy Policy"]
    }

    var createAccountButton: XCUIElement {
        app.buttons[AccessibilityID.Auth.createAccount]
    }

    var takenEmailTitle: XCUIElement {
        app.staticTexts["That email already has an account"]
    }

    @discardableResult
    func waitUntilShown(file: StaticString = #filePath, line: UInt = #line) -> SignUpScreen {
        title.expectToAppear("Expected the Create an account screen", file: file, line: line)
        return self
    }

    func fill(email: String, username: String) {
        emailField.expectToAppear().enter(email)
        usernameField.enter(username)
        // Return ends editing and closes the keyboard so the consent row is reachable.
        usernameField.typeText("\n")
    }

    func acceptTerms() {
        termsCheckbox.expectToAppear().tap()
    }

    /// Creating the account uses the app's UI-test passkey in place of the system sheet.
    func submit() {
        createAccountButton.expectToAppear().tap()
    }

    /// Asserts the inline notice shows the server's exact explanation.
    func expectFailure(message: String, file: StaticString = #filePath, line: UInt = #line) {
        app.staticTexts[message].expectToAppear("Expected the notice to say: \(message)", file: file, line: line)
    }
}
