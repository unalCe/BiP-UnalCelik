import CommonKit
import TestSupport
import XCTest

@testable import AppFeature

final class FlowPickerStringsTests: XCTestCase {
    func test_formatsTheInterpolatedFlowName() {
        XCTAssertEqual(AppStrings.FlowPicker.restart("VIPER · UIKit"), "Restart with VIPER · UIKit")
        XCTAssertEqual(AppStrings.FlowPicker.current("MVVM-C · UIKit"), "Running MVVM-C · UIKit")
    }

    func test_noStringFallsBackToItsKey() {
        XCTAssertLocalized([
            AppStrings.FlowPicker.title, AppStrings.FlowPicker.restart("MVVM-C · UIKit"),
            AppStrings.FlowPicker.current("MVVM-C · UIKit"), AppStrings.FlowPicker.viperLockReason,
            AppStrings.FlowPicker.infoButton,
        ])
    }
}
