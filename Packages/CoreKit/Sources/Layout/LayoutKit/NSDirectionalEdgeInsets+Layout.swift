import UIKit

/// Directional rather than left/right, so layouts mirror correctly in RTL.
public extension NSDirectionalEdgeInsets {
    static func all(_ value: CGFloat) -> Self {
        .init(top: value, leading: value, bottom: value, trailing: value)
    }

    static func horizontal(_ value: CGFloat) -> Self {
        .init(top: 0, leading: value, bottom: 0, trailing: value)
    }

    static func vertical(_ value: CGFloat) -> Self {
        .init(top: value, leading: 0, bottom: value, trailing: 0)
    }

    static func symmetric(horizontal: CGFloat, vertical: CGFloat) -> Self {
        .init(top: vertical, leading: horizontal, bottom: vertical, trailing: horizontal)
    }

    static func top(_ value: CGFloat) -> Self {
        .init(top: value, leading: 0, bottom: 0, trailing: 0)
    }

    static func bottom(_ value: CGFloat) -> Self {
        .init(top: 0, leading: 0, bottom: value, trailing: 0)
    }
}
