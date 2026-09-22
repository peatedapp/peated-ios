import XCTest

@MainActor
extension XCUIElement {
    /// Asserts the element appears within the timeout and returns it for chaining.
    @discardableResult
    func expectToAppear(
        timeout: TimeInterval = 10,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        XCTAssertTrue(waitForExistence(timeout: timeout), message(), file: file, line: line)
        return self
    }

    /// Asserts the element is on screen and can be tapped. Paged steps keep
    /// neighbouring pages in the hierarchy, so existence alone does not prove
    /// a step is showing.
    @discardableResult
    func expectToBeHittable(
        timeout: TimeInterval = 20,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        XCTAssertTrue(waitUntilHittable(timeout: timeout), message(), file: file, line: line)
        return self
    }

    /// Waits for the element to be on screen and tappable without failing the test.
    func waitUntilHittable(timeout: TimeInterval = 20) -> Bool {
        let hittable = NSPredicate(format: "isHittable == true")
        let result = XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: hittable, object: self)],
                                    timeout: timeout)
        return result == .completed
    }

    /// Returns once the element's frame stops moving, so a screen presented
    /// with an animation is fully on screen before it is audited or measured.
    @discardableResult
    func waitUntilStill(timeout: TimeInterval = 3) -> XCUIElement {
        let deadline = Date().addingTimeInterval(timeout)
        var previous = frame
        while Date() < deadline {
            RunLoop.current.run(until: Date().addingTimeInterval(0.15))
            let current = frame
            if current == previous, !current.isEmpty {
                return self
            }
            previous = current
        }
        return self
    }

    /// Asserts the element leaves the screen within the timeout.
    func expectToDisappear(
        timeout: TimeInterval = 10,
        _ message: @autoclosure () -> String = "",
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(waitForNonExistence(timeout: timeout), message(), file: file, line: line)
    }

    /// Focuses the field and types, replacing nothing because the field starts empty.
    func enter(_ text: String) {
        tap()
        typeText(text)
    }
}

@MainActor
extension XCUIElementQuery {
    /// Elements whose accessibility label contains the text.
    func withLabelContaining(_ text: String) -> XCUIElementQuery {
        matching(NSPredicate(format: "label CONTAINS[c] %@", text))
    }
}
