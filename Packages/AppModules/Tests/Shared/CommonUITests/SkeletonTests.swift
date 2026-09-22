import UIKit
import XCTest
@testable import CommonUI

final class SkeletonTests: XCTestCase {
    /// `shimmering()` masks the container by itself, and a mask uses alpha. A
    /// translucent fill squares its own alpha and fades the skeleton to nothing
    /// — `.secondarySystemFill` did exactly that.
    func test_fillIsOpaque() {
        for style in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: style)
            var alpha: CGFloat = 0
            Skeleton.fill.resolvedColor(with: traits).getRed(nil, green: nil, blue: nil, alpha: &alpha)

            XCTAssertEqual(alpha, 1, accuracy: 0.001, "translucent in \(style) would self-mask away")
        }
    }

    func test_fillAdaptsToTheInterfaceStyle() {
        let light = Skeleton.fill.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        let dark = Skeleton.fill.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))

        XCTAssertNotEqual(light, dark, "a fixed grey would look wrong in one of the two")
    }
}
