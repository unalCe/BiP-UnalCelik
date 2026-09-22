import ProductListInterface
import SwiftUI

/// The SwiftUI construction of `ProductListMetrics`.
enum ProductGridMetrics {
    static let gridColumns = Array(
        repeating: GridItem(.flexible(), spacing: ProductListMetrics.gutter),
        count: ProductListMetrics.columns
    )

    /// Enough to fill a screen; the real count is unknown until the response
    /// lands.
    static let skeletonCount = 8

    // text rarely fills its line, so neither do the placeholders for it
    static let skeletonTitleWidthFraction: CGFloat = 0.85
    static let skeletonPriceWidthFraction: CGFloat = 0.4
}

/// The one grid both the content and its skeleton are laid out in.
struct ProductGrid<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        LazyVGrid(columns: ProductGridMetrics.gridColumns, spacing: ProductListMetrics.gutter) {
            content
        }
        .padding(ProductListMetrics.gutter)
    }
}
