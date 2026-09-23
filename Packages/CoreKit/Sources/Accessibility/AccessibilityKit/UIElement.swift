import Foundation

/// A stable, semantic name for something on screen.
///
/// The app tags its views with these, and UI tests find the views by the same
/// value. Neither side depends on labels, copy or view hierarchy, so rewording
/// a string or restructuring a screen does not break a test.
public protocol UIElement {
    var accessibilityIdentifier: String { get }
}

public extension UIElement where Self: RawRepresentable, RawValue == String {
    var accessibilityIdentifier: String { rawValue }
}

public extension UIElement {
    /// One identifier per instance of a repeated element, e.g. a cell per
    /// product: `productList.cell.6_id_is_a_string`.
    func accessibilityIdentifier(_ suffix: String) -> String {
        "\(accessibilityIdentifier).\(suffix)"
    }
}
