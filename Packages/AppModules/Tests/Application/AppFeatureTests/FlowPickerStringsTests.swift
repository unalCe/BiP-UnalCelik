import CommonKit
import XCTest
@testable import AppFeature

final class FlowPickerStringsTests: XCTestCase {
    func test_formatsTheInterpolatedFlowName() {
        XCTAssertEqual(AppStrings.FlowPicker.open("VIPER · UIKit"), "Open VIPER · UIKit")
    }

    func test_noStringFallsBackToItsKey() {
        let all = [
            AppStrings.FlowPicker.title, AppStrings.FlowPicker.open("MVVM-C · UIKit"),
            AppStrings.FlowPicker.viperLockReason,
        ]
        for string in all {
            XCTAssertNil(
                string.range(of: #"^[a-z]+[A-Za-z]*\.[A-Za-z.]+"#, options: .regularExpression),
                "\(string) looks like an unresolved key"
            )
        }
    }
}
