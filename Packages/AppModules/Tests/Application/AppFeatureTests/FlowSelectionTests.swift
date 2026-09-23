import XCTest

@testable import AppFeature

final class FlowSelectionTests: XCTestCase {
    private var selection: FlowSelection!

    override func setUp() {
        super.setUp()
        selection = FlowSelection()
    }

    override func tearDown() {
        selection = nil
        super.tearDown()
    }

    func test_defaultsToMVVMUIKit() {
        XCTAssertEqual(selection.style, .mvvmUIKit)
    }

    func test_swiftUIUnderMVVM_isAllowed() {
        selection.select(UIFramework.swiftUI)

        XCTAssertEqual(selection.style, .mvvmSwiftUI)
    }

    func test_selectingVIPER_forcesUIKit() {
        selection.select(UIFramework.swiftUI)

        selection.select(ArchitectureStyle.viper)

        XCTAssertEqual(selection.uiFramework, .uiKit)
        XCTAssertEqual(selection.style, .viperUIKit)
    }

    func test_whileVIPERSelected_frameworkIsLockedAndExplained() {
        selection.select(ArchitectureStyle.viper)

        XCTAssertFalse(selection.isUIFrameworkSelectable)
        XCTAssertNotNil(selection.lockReason)

        selection.select(UIFramework.swiftUI)

        XCTAssertEqual(selection.uiFramework, .uiKit, "a locked framework ignores the selection")
    }

    func test_returningToMVVM_unlocksFramework() {
        selection.select(ArchitectureStyle.viper)

        selection.select(ArchitectureStyle.mvvm)

        XCTAssertTrue(selection.isUIFrameworkSelectable)
        XCTAssertNil(selection.lockReason)
    }

    func test_initRejectsIllegalCombination() {
        selection = FlowSelection(architecture: .viper, uiFramework: .swiftUI)

        XCTAssertEqual(selection.uiFramework, .uiKit)
    }

    func test_initFromStyle_roundTrips() {
        for style in FlowStyle.allCases {
            XCTAssertEqual(FlowSelection(style: style).style, style)
        }
    }
}
