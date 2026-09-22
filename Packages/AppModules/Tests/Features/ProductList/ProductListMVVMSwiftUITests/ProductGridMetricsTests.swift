import ProductListInterface
import SwiftUI
import XCTest
@testable import ProductListMVVMSwiftUI

/// `ProductListViewControllerTests` holds the UIKit cells to
/// `ProductListMetrics.itemWidth`; these hold the SwiftUI grid to the same
/// function, which is what keeps the two renderers indistinguishable.
@MainActor
final class ProductGridMetricsTests: XCTestCase {
    func test_gridColumnsAreBuiltFromTheSharedMetrics() {
        XCTAssertEqual(ProductGridMetrics.gridColumns.count, ProductListMetrics.columns)
        for column in ProductGridMetrics.gridColumns {
            XCTAssertEqual(column.spacing, ProductListMetrics.gutter)
        }
    }

    func test_renderedItemsAreAsWideAsTheSharedMetricsSay() {
        let containerWidth: CGFloat = 402
        let recorder = WidthRecorder()
        let host = UIHostingController(rootView: ProductGrid {
            ForEach(0..<ProductListMetrics.columns, id: \.self) { _ in
                GeometryReader { proxy in
                    Color.clear.onAppear { recorder.widths.append(proxy.size.width) }
                }
                .frame(height: 10)
            }
        })
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: containerWidth, height: 874))
        window.rootViewController = host
        window.makeKeyAndVisible()

        let deadline = Date().addingTimeInterval(2)
        while recorder.widths.count < ProductListMetrics.columns, Date() < deadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.01))
        }

        XCTAssertEqual(recorder.widths.count, ProductListMetrics.columns)
        for width in recorder.widths {
            XCTAssertEqual(width, ProductListMetrics.itemWidth(in: containerWidth), accuracy: 0.5)
        }
    }

    func test_itemWidthLeavesExactlyTheGutters() {
        let containerWidth: CGFloat = 402
        let occupied = ProductListMetrics.itemWidth(in: containerWidth)
            * CGFloat(ProductListMetrics.columns)
            + ProductListMetrics.gutter * CGFloat(ProductListMetrics.columns + 1)

        XCTAssertEqual(occupied, containerWidth, accuracy: 0.001)
    }
}

private final class WidthRecorder {
    var widths: [CGFloat] = []
}
