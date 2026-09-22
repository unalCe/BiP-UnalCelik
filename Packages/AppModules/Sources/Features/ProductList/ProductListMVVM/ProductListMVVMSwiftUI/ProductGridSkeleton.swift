import CommonUI
import SwiftUI

struct ProductGridSkeleton: View {
    var body: some View {
        ProductGrid {
            ForEach(0..<ProductGridMetrics.skeletonCount, id: \.self) { _ in ProductCellSkeleton() }
        }
        .shimmering()
        .accessibilityHidden(true)
    }
}
