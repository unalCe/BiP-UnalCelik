import SwiftUI

enum ProductGridMetrics {
    static let columns = 2
    static let gutter: CGFloat = 16

    static let imageCornerRadius: CGFloat = 8
    static let titleSpacing: CGFloat = 8
    static let priceSpacing: CGFloat = 4

    static let gridColumns = Array(
        repeating: GridItem(.flexible(), spacing: gutter),
        count: columns
    )

    static func itemWidth(in containerWidth: CGFloat) -> CGFloat {
        (containerWidth - gutter * CGFloat(columns + 1)) / CGFloat(columns)
    }
}
