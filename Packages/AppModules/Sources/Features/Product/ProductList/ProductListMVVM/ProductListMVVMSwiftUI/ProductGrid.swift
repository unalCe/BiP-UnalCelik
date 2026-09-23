import SwiftUI

private enum Metrics {
    static let columns = 2
    /// Gap between cells, and the padding around the whole grid.
    static let gridSpacing: CGFloat = 16

    static let gridColumns = Array(
        repeating: GridItem(.flexible(), spacing: gridSpacing),
        count: columns
    )
}

/// The one grid both the content and its skeleton are laid out in.
struct ProductGrid<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        LazyVGrid(columns: Metrics.gridColumns, spacing: Metrics.gridSpacing) {
            content
        }
        .padding(Metrics.gridSpacing)
    }
}
