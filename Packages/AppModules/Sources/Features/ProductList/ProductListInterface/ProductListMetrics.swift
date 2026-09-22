import CoreGraphics

/// The grid every renderer of the list draws. Each renderer builds its own
/// layout from these; only the numbers are shared.
public enum ProductListMetrics {
    public static let columns = 2
    public static let gutter: CGFloat = 16

    public static let imageCornerRadius: CGFloat = 8
    public static let titleSpacing: CGFloat = 8
    public static let priceSpacing: CGFloat = 4

    /// The gutter also insets the grid, so there is one more gutter than columns.
    public static func itemWidth(in containerWidth: CGFloat) -> CGFloat {
        (containerWidth - gutter * CGFloat(columns + 1)) / CGFloat(columns)
    }
}
