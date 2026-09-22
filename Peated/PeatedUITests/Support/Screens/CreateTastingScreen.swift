import XCTest

/// The six-step Add Tasting sheet. Steps are paged, so tests move with the
/// Continue and Back buttons rather than swipes.
@MainActor
struct CreateTastingScreen {
    let app: XCUIApplication

    var title: XCUIElement {
        app.navigationBars["Add Tasting"]
    }

    var cancelButton: XCUIElement {
        app.buttons[AccessibilityID.CreateTasting.cancel]
    }

    var continueButton: XCUIElement {
        app.buttons[AccessibilityID.CreateTasting.continueButton]
    }

    var submitButton: XCUIElement {
        app.buttons[AccessibilityID.CreateTasting.submit]
    }

    /// Step 1: bottle
    var bottleSearchField: XCUIElement {
        app.textFields[AccessibilityID.CreateTasting.bottleSearch]
    }

    var bottleResults: XCUIElementQuery {
        app.buttons.matching(identifier: AccessibilityID.CreateTasting.bottleResult)
    }

    var scanBarcodeButton: XCUIElement {
        app.buttons[AccessibilityID.CreateTasting.scanBarcode]
    }

    /// Step 4: location
    var atHomeButton: XCUIElement {
        app.buttons[AccessibilityID.CreateTasting.atHome]
    }

    var locationDeniedNotice: XCUIElement {
        app.otherElements[AccessibilityID.Permission.deniedNotice]
    }

    /// Step 5: photos
    var takePhotoButton: XCUIElement {
        app.buttons[AccessibilityID.CreateTasting.takePhoto]
    }

    var cameraDeniedAlert: XCUIElement {
        app.alerts["Camera Access Needed"]
    }

    var openSettingsButton: XCUIElement {
        app.buttons[AccessibilityID.Permission.openSettings]
    }

    @discardableResult
    func waitUntilShown(file: StaticString = #filePath, line: UInt = #line) -> CreateTastingScreen {
        title.expectToAppear("Expected the Add Tasting sheet", file: file, line: line)
        return self
    }

    func ratingButton(_ band: String) -> XCUIElement {
        app.buttons[AccessibilityID.CreateTasting.rating(band)]
    }

    /// Searches for the bottle and picks the first result, which moves to the rating step.
    func selectBottle(named name: String, file: StaticString = #filePath, line: UInt = #line) {
        bottleSearchField.expectToAppear(file: file, line: line).enter(name)
        bottleResults.firstMatch.expectToAppear("Expected a search result for \(name)", file: file, line: line).tap()
        ratingButton("very_good").expectToBeHittable("Expected the rating step", file: file, line: line)
    }

    func tapContinue(file: StaticString = #filePath, line: UInt = #line) {
        continueButton.expectToAppear(file: file, line: line).tap()
    }

    /// Moves from the rating step to the location step.
    func continueToLocationStep(file: StaticString = #filePath, line: UInt = #line) {
        tapContinue(file: file, line: line) // notes
        tapContinue(file: file, line: line) // location
        atHomeButton.expectToBeHittable("Expected the location step", file: file, line: line)
    }

    /// Records a tasting of the bottle at home with a rating and no photo,
    /// then waits for the sheet to close.
    func recordTasting(bottleNamed name: String, file: StaticString = #filePath, line: UInt = #line) {
        selectBottle(named: name, file: file, line: line)
        ratingButton("very_good").tap()
        continueToLocationStep(file: file, line: line)
        // The location prompt is answered so it cannot cover the step's controls.
        SystemPermissionAlert.deny()
        atHomeButton.tap()
        tapContinue(file: file, line: line) // photos
        takePhotoButton.expectToBeHittable("Expected the photos step", file: file, line: line)
        tapContinue(file: file, line: line) // confirmation
        submitButton.expectToBeHittable("Expected the confirmation step", file: file, line: line).tap()
        title.expectToDisappear(timeout: 15, "Expected the tasting to be saved and the sheet to close",
                                file: file, line: line)
    }
}
