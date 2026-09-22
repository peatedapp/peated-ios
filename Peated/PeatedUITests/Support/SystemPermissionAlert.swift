import XCTest

/// The system permission prompts belong to SpringBoard, not the app, so they
/// are driven through SpringBoard's own element tree.
enum SystemPermissionAlert {
    static let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")

    /// Taps "Don't Allow" on the next permission prompt. Returns false when no
    /// prompt appeared, for example because the permission was already decided.
    @discardableResult
    static func deny(timeout: TimeInterval = 5) -> Bool {
        // iOS spells the button with a curly apostrophe; match on the prefix.
        let button = springboard.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Don'")).firstMatch
        guard button.waitForExistence(timeout: timeout) else { return false }
        button.tap()
        return true
    }
}
