import UIKit
import XCTest
@testable import LayoutKit

@MainActor
final class LayoutKitTests: XCTestCase {
    private func makeContainer() -> UIView {
        UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 400))
    }

    func test_accessingLayout_disablesAutoresizingTranslation() {
        let view = UIView()
        _ = view.layout
        XCTAssertFalse(view.translatesAutoresizingMaskIntoConstraints)
    }

    func test_pinnedToEdges_matchesContainerExactly() {
        let container = makeContainer()
        let child = UIView()
        container.addSubview(child, pinnedToEdges: .zero)

        container.layoutIfNeeded()

        XCTAssertEqual(child.frame, container.bounds)
    }

    func test_pinnedToEdges_appliesInsets() {
        let container = makeContainer()
        let child = UIView()
        container.addSubview(child, pinnedToEdges: .all(16))

        container.layoutIfNeeded()

        XCTAssertEqual(child.frame, container.bounds.insetBy(dx: 16, dy: 16))
    }

    func test_horizontalInsets_leaveVerticalUnconstrained() {
        let container = makeContainer()
        let child = UIView()
        container.addSubview(child)
        child.layout
            .pinHorizontally(to: container, insets: .horizontal(20))
            .height(50)
            .top(to: container.topAnchor)

        container.layoutIfNeeded()

        XCTAssertEqual(child.frame, CGRect(x: 20, y: 0, width: 160, height: 50))
    }

    func test_center_placesViewInTheMiddle() {
        let container = makeContainer()
        let child = UIView()
        container.addSubview(child, centeredIn: nil)
        child.layout.size(40)

        container.layoutIfNeeded()

        XCTAssertEqual(child.center, CGPoint(x: 100, y: 200))
        XCTAssertEqual(child.bounds.size, CGSize(width: 40, height: 40))
    }

    func test_below_stacksWithSpacing() {
        let container = makeContainer()
        let top = UIView()
        let bottom = UIView()
        container.addSubview(top)
        container.addSubview(bottom)

        top.layout.pinHorizontally(to: container).top(to: container.topAnchor).height(30)
        bottom.layout.pinHorizontally(to: container).below(top, spacing: 8).height(30)

        container.layoutIfNeeded()

        XCTAssertEqual(bottom.frame.minY, top.frame.maxY + 8)
    }

    func test_after_placesAlongReadingDirection() {
        let container = makeContainer()
        let leading = UIView()
        let trailing = UIView()
        container.addSubview(leading)
        container.addSubview(trailing)

        leading.layout.leading(to: container.leadingAnchor).centerY(to: container).size(40)
        trailing.layout.after(leading, spacing: 12).centerY(to: container).size(40)

        container.layoutIfNeeded()

        XCTAssertEqual(trailing.frame.minX, leading.frame.maxX + 12)
    }

    func test_aspectRatio_derivesHeightFromWidth() {
        let container = makeContainer()
        let child = UIView()
        container.addSubview(child)
        child.layout
            .pinHorizontally(to: container)
            .top(to: container.topAnchor)
            .aspectRatio(2)

        container.layoutIfNeeded()

        XCTAssertEqual(child.frame.width, 200)
        XCTAssertEqual(child.frame.height, 100)
    }

    func test_greaterThanOrEqualRelation_isHonoured() {
        let container = makeContainer()
        let child = UIView()
        container.addSubview(child)
        child.layout
            .center(in: container)
            .leading(to: container.leadingAnchor, constant: 24, relation: .greaterThanOrEqual)
            .height(20)

        container.layoutIfNeeded()

        XCTAssertGreaterThanOrEqual(child.frame.minX, 24)
    }

    func test_insetHelpers() {
        XCTAssertEqual(NSDirectionalEdgeInsets.all(8),
                       .init(top: 8, leading: 8, bottom: 8, trailing: 8))
        XCTAssertEqual(NSDirectionalEdgeInsets.symmetric(horizontal: 16, vertical: 4),
                       .init(top: 4, leading: 16, bottom: 4, trailing: 16))
        XCTAssertEqual(NSDirectionalEdgeInsets.vertical(10),
                       .init(top: 10, leading: 0, bottom: 10, trailing: 0))
    }
}
