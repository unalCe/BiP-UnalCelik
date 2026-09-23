import AccessibilityKit
import XCTest

/// Base for page objects. A page knows how to find its elements and what
/// the user can do on it; the test keeps the expectations. Actions that move
/// to another screen return that screen's page, so a journey reads as a chain.
class Page {
    let app = XCUIApplication()

    /// Finds an element by identifier regardless of its type, so a UIKit cell
    /// and a SwiftUI button with the same identifier are looked up the same way.
    func element(_ element: UIElement, suffix: String? = nil) -> XCUIElement {
        let identifier = suffix.map(element.accessibilityIdentifier) ?? element.accessibilityIdentifier
        return app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    /// Waits until `element` reaches `status`, failing the test on timeout.
    /// Returns as soon as the condition holds; it never waits a fixed delay.
    @discardableResult
    func expect(
        _ element: XCUIElement,
        _ status: UIStatus,
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        if !status.wait(for: element, timeout: timeout) {
            XCTFail("\(element) did not become \(status) within \(timeout)s", file: file, line: line)
        }
        return element
    }
}

enum UIStatus: CustomStringConvertible {
    case exists
    case notExists
    case hittable
    case labelEquals(String)

    /// Checks once, then waits only if the UI is not there yet. XCTest's
    /// waits poll about once a second and sleep before their first check,
    /// which would cost a second per assertion even when the UI is ready.
    func wait(for element: XCUIElement, timeout: TimeInterval) -> Bool {
        isSatisfied(by: element) || waitUntilSatisfied(by: element, timeout: timeout)
    }

    private func isSatisfied(by element: XCUIElement) -> Bool {
        switch self {
        case .exists: return element.exists
        case .notExists: return !element.exists
        case .hittable: return element.exists && element.isHittable
        case .labelEquals(let text): return element.exists && element.label == text
        }
    }

    private func waitUntilSatisfied(by element: XCUIElement, timeout: TimeInterval) -> Bool {
        switch self {
        case .exists: return element.waitForExistence(timeout: timeout)
        case .notExists: return element.waitForNonExistence(timeout: timeout)
        case .hittable: return element.wait(for: \.isHittable, toEqual: true, timeout: timeout)
        case .labelEquals(let text): return element.wait(for: \.label, toEqual: text, timeout: timeout)
        }
    }

    var description: String {
        switch self {
        case .exists: return "existing"
        case .notExists: return "gone"
        case .hittable: return "hittable"
        case .labelEquals(let text): return "labelled \"\(text)\""
        }
    }
}
