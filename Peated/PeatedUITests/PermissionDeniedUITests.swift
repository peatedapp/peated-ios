import XCTest

/// A refused camera or location permission must leave the member with an
/// explanation and a way to Settings, never a blank or dead control.
///
/// Each test resets the permission before launch so the system prompt is
/// shown, refuses it there, and then checks the app's own recovery message.
final class PermissionDeniedUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testBarcodeScannerExplainsDeniedCamera() {
        let stubs = [APIStub].signedInBaseline() + [APIStub].createTasting()
        let app = AppLaunch.launch(session: .signedIn, stubs: stubs, resetting: [.camera])
        let flow = HomeScreen(app: app).waitUntilShown().openRecordTasting()

        flow.scanBarcodeButton.expectToAppear().tap()
        XCTAssertTrue(SystemPermissionAlert.deny(), "Expected the system camera prompt")

        expectCameraDeniedAlert(flow)
        flow.cameraDeniedAlert.buttons["Cancel"].tap()

        // A later attempt, with the refusal remembered by the system, gets the same help.
        app.terminate()
        app.launch()
        HomeScreen(app: app).waitUntilShown().openRecordTasting().scanBarcodeButton.expectToAppear().tap()
        expectCameraDeniedAlert(flow)
    }

    @MainActor
    func testTakePhotoExplainsDeniedCamera() {
        let stubs = [APIStub].signedInBaseline() + [APIStub].createTasting()
        let app = AppLaunch.launch(session: .signedIn, stubs: stubs, resetting: [.camera, .location])
        SystemPermissionAlert.denyInterruptions(in: self)
        let flow = HomeScreen(app: app).waitUntilShown().openRecordTasting()

        flow.selectBottle(named: Fixtures.bottleName)
        flow.continueToLocationStep()
        flow.tapContinue()
        flow.takePhotoButton.expectToBeHittable("Expected the photos step").tap()
        XCTAssertTrue(SystemPermissionAlert.deny(), "Expected the system camera prompt")

        expectCameraDeniedAlert(flow)
    }

    @MainActor
    func testLocationStepExplainsDeniedLocation() {
        let stubs = [APIStub].signedInBaseline() + [APIStub].createTasting()
        let app = AppLaunch.launch(session: .signedIn, stubs: stubs, resetting: [.location])
        SystemPermissionAlert.denyInterruptions(in: self)
        let flow = HomeScreen(app: app).waitUntilShown().openRecordTasting()

        flow.selectBottle(named: Fixtures.bottleName)
        flow.continueToLocationStep()

        flow.locationDeniedNotice.expectToAppear("Expected the location-off notice")
        XCTAssertTrue(flow.openSettingsButton.isHittable, "The notice must offer Settings")
        XCTAssertTrue(flow.atHomeButton.isEnabled, "At Home stays available without location")
    }

    @MainActor
    private func expectCameraDeniedAlert(_ flow: CreateTastingScreen, file: StaticString = #filePath,
                                         line: UInt = #line) {
        flow.cameraDeniedAlert.expectToAppear("Expected the camera-off alert", file: file, line: line)
        XCTAssertTrue(flow.cameraDeniedAlert.buttons["Open Settings"].exists,
                      "The alert must offer Settings", file: file, line: line)
    }
}
