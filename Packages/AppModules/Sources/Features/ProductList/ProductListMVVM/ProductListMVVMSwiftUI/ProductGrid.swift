import SwiftUI

private enum Metrics {
    static let columns = 2
    static let gutter: CGFloat = 16

    static let gridColumns = Array(
        repeating: GridItem(.flexible(), spacing: gutter),
        count: columns
    )
}

/// The one grid both the content and its skeleton are laid out in.
struct ProductGrid<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        LazyVGrid(columns: Metrics.gridColumns, spacing: Metrics.gutter) {
            content
        }
        .padding(Metrics.gutter)
    }
}
