import CommonKit
import XCTest
@testable import AppFeature

final class FlowPickerStringsTests: XCTestCase {
    func test_formatsTheInterpolatedFlowName() {
        XCTAssertEqual(AppStrings.FlowPicker.restart("VIPER · UIKit"), "Restart with VIPER · UIKit")
        XCTAssertEqual(AppStrings.FlowPicker.current("MVVM-C · UIKit"), "Running MVVM-C · UIKit")
    }

    func test_noStringFallsBackToItsKey() {
        let all = [
            AppStrings.FlowPicker.title, AppStrings.FlowPicker.restart("MVVM-C · UIKit"),
            AppStrings.FlowPicker.current("MVVM-C · UIKit"), AppStrings.FlowPicker.viperLockReason,
            AppStrings.FlowPicker.infoButton,
        ]
        for string in all {
            XCTAssertNil(
                string.range(of: #"^[a-z]+[A-Za-z]*\.[A-Za-z.]+"#, options: .regularExpression),
                "\(string) looks like an unresolved key"
            )
        }
    }
}
