import UIKit

/// Anything with layout anchors — a view, or a layout guide such as
/// `safeAreaLayoutGuide` or `readableContentGuide`.
public protocol LayoutAnchorable {
    var topAnchor: NSLayoutYAxisAnchor { get }
    var bottomAnchor: NSLayoutYAxisAnchor { get }
    var leadingAnchor: NSLayoutXAxisAnchor { get }
    var trailingAnchor: NSLayoutXAxisAnchor { get }
    var centerXAnchor: NSLayoutXAxisAnchor { get }
    var centerYAnchor: NSLayoutYAxisAnchor { get }
    var widthAnchor: NSLayoutDimension { get }
    var heightAnchor: NSLayoutDimension { get }
}

extension UIView: LayoutAnchorable {}
extension UILayoutGuide: LayoutAnchorable {}

public extension UIView {
    /// `safeAreaLayoutGuide`, spelled to read well at a call site:
    /// `child.layout.pinEdges(to: container.safeArea)`
    var safeArea: LayoutAnchorable { safeAreaLayoutGuide }
}
