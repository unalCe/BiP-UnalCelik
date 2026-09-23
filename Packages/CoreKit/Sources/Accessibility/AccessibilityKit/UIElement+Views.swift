import SwiftUI
import UIKit

public extension UIView {
    /// Tags the view so a UI test can find it by `element`.
    func setAccessibilityIdentifier(_ element: UIElement, suffix: String? = nil) {
        accessibilityIdentifier = suffix.map(element.accessibilityIdentifier) ?? element.accessibilityIdentifier
    }
}

public extension UIBarButtonItem {
    func setAccessibilityIdentifier(_ element: UIElement) {
        accessibilityIdentifier = element.accessibilityIdentifier
    }
}

public extension View {
    /// Tags the view so a UI test can find it by `element`.
    func accessibilityIdentifier(_ element: UIElement, suffix: String? = nil) -> some View {
        accessibilityIdentifier(suffix.map(element.accessibilityIdentifier) ?? element.accessibilityIdentifier)
    }
}
