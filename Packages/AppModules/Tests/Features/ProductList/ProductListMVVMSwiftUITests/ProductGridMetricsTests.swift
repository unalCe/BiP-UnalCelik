import XCTest
@testable import ProductListMVVMSwiftUI
@testable import ProductListMVVMUIKit

/// The two renderers are meant to be indistinguishable, and nothing but this
/// stops their numbers drifting apart.
final class ProductGridMetricsTests: XCTestCase {
    func test_columnsAndGutterMatchTheUIKitLayout() {
        XCTAssertEqual(ProductGridMetrics.columns, ProductListLayout.columns)
        XCTAssertEqual(ProductGridMetrics.gutter, ProductListLayout.gutter)
    }

    func test_itemWidthMatchesTheUIKitLayout() {
        for containerWidth in [320, 390, 402, 430, 768] as [CGFloat] {
            XCTAssertEqual(
                ProductGridMetrics.itemWidth(in: containerWidth),
                ProductListLayout.itemWidth(in: containerWidth),
                accuracy: 0.001,
                "widths diverge at \(containerWidth)"
            )
        }
    }

    /// The compositional layout insets the section and the item separately, so
    /// the SwiftUI padding has to be their sum to land in the same place.
    func test_gutterIsWhatTheItemWidthImplies() {
        let containerWidth: CGFloat = 402
        let occupied = ProductGridMetrics.itemWidth(in: containerWidth)
            * CGFloat(ProductGridMetrics.columns)
            + ProductGridMetrics.gutter * CGFloat(ProductGridMetrics.columns + 1)

        XCTAssertEqual(occupied, containerWidth, accuracy: 0.001)
    }
}
