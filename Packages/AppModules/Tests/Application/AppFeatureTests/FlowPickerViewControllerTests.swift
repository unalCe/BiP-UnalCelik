import CommonKit
import UIKit
import XCTest
@testable import AppFeature

@MainActor
final class FlowPickerViewControllerTests: XCTestCase {
    func test_showsTheRunningArchitecture() {
        let sut = FlowPickerViewController(currentStyle: .viperUIKit) { _ in }
        sut.loadViewIfNeeded()

        XCTAssertTrue(labels(in: sut).contains(AppStrings.FlowPicker.current("VIPER · UIKit")))
    }

    func test_restartIsDisabledUntilAnotherStyleIsPicked() {
        var restarted: [FlowStyle] = []
        let sut = FlowPickerViewController(currentStyle: .mvvmUIKit) { restarted.append($0) }
        sut.loadViewIfNeeded()

        XCTAssertEqual(restartButton(in: sut)?.isEnabled, false)

        let architecture = segmentedControls(in: sut).first
        architecture?.selectedSegmentIndex = ArchitectureStyle.allCases.firstIndex(of: .viper)!
        architecture.map { fire($0, .valueChanged) }
        restartButton(in: sut).map { fire($0, .touchUpInside) }

        XCTAssertEqual(restartButton(in: sut)?.isEnabled, true)
        XCTAssertEqual(restarted, [.viperUIKit])
    }

    // MARK: - Helpers

    /// `sendActions(for:)` routes through `UIApplication`, which a package test
    /// bundle does not have, so the registered actions are invoked directly.
    private func fire(_ control: UIControl, _ event: UIControl.Event) {
        for target in control.allTargets {
            for action in control.actions(forTarget: target, forControlEvent: event) ?? [] {
                _ = (target as NSObject).perform(Selector(action))
            }
        }
    }

    private func allSubviews(of view: UIView) -> [UIView] {
        view.subviews + view.subviews.flatMap(allSubviews(of:))
    }

    private func labels(in controller: UIViewController) -> [String] {
        allSubviews(of: controller.view).compactMap { ($0 as? UILabel)?.text }
    }

    private func segmentedControls(in controller: UIViewController) -> [UISegmentedControl] {
        allSubviews(of: controller.view).compactMap { $0 as? UISegmentedControl }
    }

    private func restartButton(in controller: UIViewController) -> UIButton? {
        allSubviews(of: controller.view).compactMap { $0 as? UIButton }
            .first { $0.configuration != nil }
    }
}
