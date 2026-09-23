import XCTest
@testable import AppFeature

final class FlowSelectionTests: XCTestCase {
    func test_defaultsToMVVMUIKit() {
        XCTAssertEqual(FlowSelection().style, .mvvmUIKit)
    }

    func test_swiftUIUnderMVVM_isAllowed() {
        var sut = FlowSelection()
        sut.select(UIFramework.swiftUI)
        XCTAssertEqual(sut.style, .mvvmSwiftUI)
    }

    func test_selectingVIPER_forcesUIKit() {
        var sut = FlowSelection()
        sut.select(UIFramework.swiftUI)
        sut.select(ArchitectureStyle.viper)

        XCTAssertEqual(sut.uiFramework, .uiKit)
        XCTAssertEqual(sut.style, .viperUIKit)
    }

    func test_whileVIPERSelected_frameworkIsLockedAndExplained() {
        var sut = FlowSelection()
        sut.select(ArchitectureStyle.viper)

        XCTAssertFalse(sut.isUIFrameworkSelectable)
        XCTAssertNotNil(sut.lockReason)

        sut.select(UIFramework.swiftUI)  // ignored
        XCTAssertEqual(sut.uiFramework, .uiKit)
    }

    func test_returningToMVVM_unlocksFramework() {
        var sut = FlowSelection()
        sut.select(ArchitectureStyle.viper)
        sut.select(ArchitectureStyle.mvvm)

        XCTAssertTrue(sut.isUIFrameworkSelectable)
        XCTAssertNil(sut.lockReason)
    }

    func test_initRejectsIllegalCombination() {
        XCTAssertEqual(FlowSelection(architecture: .viper, uiFramework: .swiftUI).uiFramework, .uiKit)
    }

    func test_initFromStyle_roundTrips() {
        for style in FlowStyle.allCases {
            XCTAssertEqual(FlowSelection(style: style).style, style)
        }
    }
}
