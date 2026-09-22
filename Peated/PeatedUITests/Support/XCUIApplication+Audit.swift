import XCTest

@MainActor
extension XCUIApplication {
    /// Runs the accessibility audit for the current screen.
    ///
    /// Dynamic Type findings on navigation bar buttons are ignored: the system
    /// bar keeps its buttons at a fixed size, which the audit reports as
    /// partial support. Everything else fails the test.
    func auditAccessibility() throws {
        try performAccessibilityAudit { issue in
            guard issue.auditType == .dynamicType, let element = issue.element else { return false }
            let bar = self.navigationBars.firstMatch
            return bar.exists && bar.frame.contains(element.frame)
        }
    }
}
