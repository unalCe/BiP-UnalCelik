import SwiftUI
import XCTest
@testable import ProductListMVVMSwiftUI

/// The grid's numbers are private to it, so this holds what it draws: two
/// columns with a 16pt spacing between and around them.
@MainActor
final class ProductGridTests: XCTestCase {
    func test_rendersTwoColumnsLeavingTheGridSpacing() {
        let containerWidth: CGFloat = 402
        let recorder = WidthRecorder()
        let host = UIHostingController(rootView: ProductGrid {
            ForEach(0..<2, id: \.self) { _ in
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
        while recorder.widths.count < 2, Date() < deadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.01))
        }

        XCTAssertEqual(recorder.widths.count, 2)
        for width in recorder.widths {
            XCTAssertEqual(width, (containerWidth - 16 * 3) / 2, accuracy: 0.5)
        }
    }
}

private final class WidthRecorder {
    var widths: [CGFloat] = []
}
