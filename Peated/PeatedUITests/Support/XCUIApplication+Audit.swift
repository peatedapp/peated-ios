import XCTest

@MainActor
extension XCUIApplication {
    /// Runs the accessibility audit for the current screen.
    ///
    /// Two platform behaviours are ignored; everything else fails the test:
    /// - Dynamic Type on navigation bar buttons, which the system bar keeps at a
    ///   fixed size and the audit reports as partial support.
    /// - Clipped text in a single-line text field, which truncates a long
    ///   placeholder at large sizes instead of wrapping.
    func auditAccessibility() throws {
        try performAccessibilityAudit { issue in
            guard let element = issue.element else { return false }
            switch issue.auditType {
            case .dynamicType:
                let bar = self.navigationBars.firstMatch
                return bar.exists && bar.frame.contains(element.frame)
            case .textClipped:
                return element.elementType == .textField || element.elementType == .secureTextField
            default:
                return false
            }
        }
    }
}
