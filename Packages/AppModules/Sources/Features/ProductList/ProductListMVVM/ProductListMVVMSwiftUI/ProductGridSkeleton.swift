import CommonUI
import SwiftUI

private enum Metrics {
    /// Enough to fill a screen; the real count is unknown until the response
    /// lands.
    static let skeletonCount = 8
}

struct ProductGridSkeleton: View {
    var body: some View {
        ProductGrid {
            ForEach(0..<Metrics.skeletonCount, id: \.self) { _ in ProductCellSkeleton() }
        }
        .shimmering()
        .accessibilityHidden(true)
    }
}
