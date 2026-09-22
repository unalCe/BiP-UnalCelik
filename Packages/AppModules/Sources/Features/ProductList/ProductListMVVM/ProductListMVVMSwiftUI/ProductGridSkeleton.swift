import CommonUI
import SwiftUI

struct ProductGridSkeleton: View {
    /// Enough to fill a screen; the real count is unknown until the response
    /// lands.
    var count: Int = 8

    var body: some View {
        LazyVGrid(
            columns: ProductGridMetrics.gridColumns,
            spacing: ProductGridMetrics.gutter
        ) {
            ForEach(0..<count, id: \.self) { _ in ProductCellSkeleton() }
        }
        .padding(ProductGridMetrics.gutter)
        .shimmering()
        .accessibilityHidden(true)
    }
}
