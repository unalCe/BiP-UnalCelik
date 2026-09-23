import XCTest

@testable import CommonKit

final class ViewStateTests: XCTestCase {
    private let error = ErrorDisplayModel(title: "title", message: "message")

    func test_value_isOnlyPresentWhenLoaded() {
        XCTAssertEqual(ViewState<Int>.loaded(1).value, 1)
        XCTAssertNil(ViewState<Int>.loading.value)
        XCTAssertNil(ViewState<Int>.empty.value)
        XCTAssertNil(ViewState<Int>.failed(error).value)
    }

    func test_failure_isOnlyPresentWhenFailed() {
        XCTAssertEqual(ViewState<Int>.failed(error).failure, error)
        XCTAssertNil(ViewState<Int>.loaded(1).failure)
        XCTAssertNil(ViewState<Int>.idle.failure)
    }

    func test_flags() {
        XCTAssertTrue(ViewState<Int>.idle.isIdle)
        XCTAssertTrue(ViewState<Int>.loading.isLoading)
        XCTAssertFalse(ViewState<Int>.loaded(1).isLoading)
        XCTAssertFalse(ViewState<Int>.loading.isIdle)
    }
}
