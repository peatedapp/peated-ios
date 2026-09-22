import XCTest

/// The system permission prompts belong to SpringBoard, not the app, so they
/// are driven through SpringBoard's own element tree.
@MainActor
enum SystemPermissionAlert {
    static let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

    /// iOS spells the button with a curly apostrophe; match on the prefix.
    private static let denyButton = NSPredicate(format: "label BEGINSWITH 'Don'")

    /// Answers "Don't Allow" to any permission prompt that interrupts a later
    /// interaction. The paged Add Tasting flow can raise the location prompt
    /// one step early, so the prompt is often gone before a test looks for it.
    static func denyInterruptions(in testCase: XCTestCase) {
        testCase.addUIInterruptionMonitor(withDescription: "Deny permission prompt") { alert in
            let button = alert.buttons.matching(denyButton).firstMatch
            guard button.exists else { return false }
            button.tap()
            return true
        }
    }

    /// Taps "Don't Allow" on the next permission prompt. Returns false when no
    /// prompt appeared, for example because the permission was already decided.
    @discardableResult
    static func deny(timeout: TimeInterval = 5) -> Bool {
        let button = springboard.buttons.matching(denyButton).firstMatch
        guard button.waitForExistence(timeout: timeout) else { return false }
        button.tap()
        return true
    }
}
