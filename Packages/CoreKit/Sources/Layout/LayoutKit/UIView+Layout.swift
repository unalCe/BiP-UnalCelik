import UIKit

@MainActor
public extension UIView {
    var layout: LayoutProxy { LayoutProxy(view: self) }

    /// Adds `subview` and pins all four edges.
    ///
    ///     container.addSubview(spinner, pinnedToEdges: .all(16))
    @discardableResult
    func addSubview(
        _ subview: UIView,
        pinnedToEdges insets: NSDirectionalEdgeInsets = .zero
    ) -> LayoutProxy {
        addSubview(subview)
        return subview.layout.pinEdges(to: self, insets: insets)
    }

    /// Adds `subview` and pins it to the safe area rather than the view's own
    /// edges — the usual choice for a screen's root content.
    @discardableResult
    func addSubview(
        _ subview: UIView,
        pinnedToSafeArea insets: NSDirectionalEdgeInsets = .zero
    ) -> LayoutProxy {
        addSubview(subview)
        return subview.layout.pinEdges(to: safeAreaLayoutGuide, insets: insets)
    }

    /// Adds `subview` and centres it.
    @discardableResult
    func addSubview(_ subview: UIView, centeredIn target: LayoutAnchorable? = nil) -> LayoutProxy {
        addSubview(subview)
        return subview.layout.center(in: target ?? self)
    }

    /// Adds `subview` and hands back its proxy for further constraints.
    ///
    ///     container.addSubview(label) { $0.below(icon, spacing: 8) }
    @discardableResult
    func addSubview(_ subview: UIView, layout configure: (LayoutProxy) -> Void) -> LayoutProxy {
        addSubview(subview)
        let proxy = subview.layout
        configure(proxy)
        return proxy
    }
}
