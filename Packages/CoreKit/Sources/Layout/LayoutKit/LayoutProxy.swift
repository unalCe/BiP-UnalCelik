import UIKit

/// Fluent constraint builder. Every method activates immediately and returns
/// self, so calls chain:
///
///     label.layout
///         .below(icon, spacing: 8)
///         .pinHorizontally(to: container, insets: .horizontal(16))
///
/// Accessing `.layout` sets `translatesAutoresizingMaskIntoConstraints = false`.
@MainActor
public struct LayoutProxy {
    private let view: UIView

    init(view: UIView) {
        self.view = view
        view.translatesAutoresizingMaskIntoConstraints = false
    }

    // MARK: - Edges

    @discardableResult
    public func pinEdges(
        to target: LayoutAnchorable,
        insets: NSDirectionalEdgeInsets = .zero
    ) -> Self {
        activate([
            view.topAnchor.constraint(equalTo: target.topAnchor, constant: insets.top),
            view.leadingAnchor.constraint(equalTo: target.leadingAnchor, constant: insets.leading),
            view.bottomAnchor.constraint(equalTo: target.bottomAnchor, constant: -insets.bottom),
            view.trailingAnchor.constraint(equalTo: target.trailingAnchor, constant: -insets.trailing),
        ])
    }

    @discardableResult
    public func pinHorizontally(
        to target: LayoutAnchorable,
        insets: NSDirectionalEdgeInsets = .zero
    ) -> Self {
        activate([
            view.leadingAnchor.constraint(equalTo: target.leadingAnchor, constant: insets.leading),
            view.trailingAnchor.constraint(equalTo: target.trailingAnchor, constant: -insets.trailing),
        ])
    }

    @discardableResult
    public func pinVertically(
        to target: LayoutAnchorable,
        insets: NSDirectionalEdgeInsets = .zero
    ) -> Self {
        activate([
            view.topAnchor.constraint(equalTo: target.topAnchor, constant: insets.top),
            view.bottomAnchor.constraint(equalTo: target.bottomAnchor, constant: -insets.bottom),
        ])
    }

    // MARK: - Individual edges

    @discardableResult
    public func top(
        to anchor: NSLayoutYAxisAnchor,
        constant: CGFloat = 0,
        relation: NSLayoutConstraint.Relation = .equal
    ) -> Self {
        activate([constrain(view.topAnchor, to: anchor, constant: constant, relation: relation)])
    }

    @discardableResult
    public func bottom(
        to anchor: NSLayoutYAxisAnchor,
        constant: CGFloat = 0,
        relation: NSLayoutConstraint.Relation = .equal
    ) -> Self {
        activate([constrain(view.bottomAnchor, to: anchor, constant: -constant, relation: relation)])
    }

    @discardableResult
    public func leading(
        to anchor: NSLayoutXAxisAnchor,
        constant: CGFloat = 0,
        relation: NSLayoutConstraint.Relation = .equal
    ) -> Self {
        activate([constrain(view.leadingAnchor, to: anchor, constant: constant, relation: relation)])
    }

    @discardableResult
    public func trailing(
        to anchor: NSLayoutXAxisAnchor,
        constant: CGFloat = 0,
        relation: NSLayoutConstraint.Relation = .equal
    ) -> Self {
        activate([constrain(view.trailingAnchor, to: anchor, constant: -constant, relation: relation)])
    }

    // MARK: - Centring

    @discardableResult
    public func center(in target: LayoutAnchorable) -> Self {
        activate([
            view.centerXAnchor.constraint(equalTo: target.centerXAnchor),
            view.centerYAnchor.constraint(equalTo: target.centerYAnchor),
        ])
    }

    @discardableResult
    public func centerX(to target: LayoutAnchorable, constant: CGFloat = 0) -> Self {
        activate([view.centerXAnchor.constraint(equalTo: target.centerXAnchor, constant: constant)])
    }

    @discardableResult
    public func centerY(to target: LayoutAnchorable, constant: CGFloat = 0) -> Self {
        activate([view.centerYAnchor.constraint(equalTo: target.centerYAnchor, constant: constant)])
    }

    // MARK: - Size

    @discardableResult
    public func size(width: CGFloat, height: CGFloat) -> Self {
        activate([
            view.widthAnchor.constraint(equalToConstant: width),
            view.heightAnchor.constraint(equalToConstant: height),
        ])
    }

    @discardableResult
    public func size(_ side: CGFloat) -> Self {
        size(width: side, height: side)
    }

    @discardableResult
    public func width(_ constant: CGFloat, relation: NSLayoutConstraint.Relation = .equal) -> Self {
        switch relation {
        case .lessThanOrEqual:
            return activate([view.widthAnchor.constraint(lessThanOrEqualToConstant: constant)])
        case .greaterThanOrEqual:
            return activate([view.widthAnchor.constraint(greaterThanOrEqualToConstant: constant)])
        default:
            return activate([view.widthAnchor.constraint(equalToConstant: constant)])
        }
    }

    @discardableResult
    public func height(_ constant: CGFloat, relation: NSLayoutConstraint.Relation = .equal) -> Self {
        switch relation {
        case .lessThanOrEqual:
            return activate([view.heightAnchor.constraint(lessThanOrEqualToConstant: constant)])
        case .greaterThanOrEqual:
            return activate([view.heightAnchor.constraint(greaterThanOrEqualToConstant: constant)])
        default:
            return activate([view.heightAnchor.constraint(equalToConstant: constant)])
        }
    }

    @discardableResult
    public func aspectRatio(_ ratio: CGFloat) -> Self {
        activate([view.widthAnchor.constraint(equalTo: view.heightAnchor, multiplier: ratio)])
    }

    @discardableResult
    public func matchWidth(of target: LayoutAnchorable, multiplier: CGFloat = 1) -> Self {
        activate([view.widthAnchor.constraint(equalTo: target.widthAnchor, multiplier: multiplier)])
    }

    // MARK: - Relative positioning

    @discardableResult
    public func below(_ sibling: LayoutAnchorable, spacing: CGFloat = 0) -> Self {
        activate([view.topAnchor.constraint(equalTo: sibling.bottomAnchor, constant: spacing)])
    }

    @discardableResult
    public func above(_ sibling: LayoutAnchorable, spacing: CGFloat = 0) -> Self {
        activate([view.bottomAnchor.constraint(equalTo: sibling.topAnchor, constant: -spacing)])
    }

    /// Places this view after `sibling` along the reading direction.
    @discardableResult
    public func after(_ sibling: LayoutAnchorable, spacing: CGFloat = 0) -> Self {
        activate([view.leadingAnchor.constraint(equalTo: sibling.trailingAnchor, constant: spacing)])
    }

    @discardableResult
    public func before(_ sibling: LayoutAnchorable, spacing: CGFloat = 0) -> Self {
        activate([view.trailingAnchor.constraint(equalTo: sibling.leadingAnchor, constant: -spacing)])
    }

    // MARK: -

    @discardableResult
    private func activate(_ constraints: [NSLayoutConstraint]) -> Self {
        NSLayoutConstraint.activate(constraints)
        return self
    }

    private func constrain<Anchor: AnyObject>(
        _ from: NSLayoutAnchor<Anchor>,
        to target: NSLayoutAnchor<Anchor>,
        constant: CGFloat,
        relation: NSLayoutConstraint.Relation
    ) -> NSLayoutConstraint {
        switch relation {
        case .lessThanOrEqual:
            return from.constraint(lessThanOrEqualTo: target, constant: constant)
        case .greaterThanOrEqual:
            return from.constraint(greaterThanOrEqualTo: target, constant: constant)
        default:
            return from.constraint(equalTo: target, constant: constant)
        }
    }
}
