import SharedDomain
import XCTest

@testable import CommonKit

final class ErrorPresenterTests: XCTestCase {
    private var presenter: ErrorPresenter!

    override func setUp() {
        super.setUp()
        presenter = ErrorPresenter()
    }

    override func tearDown() {
        presenter = nil
        super.tearDown()
    }

    func test_serverError_showsTheBackendsMessage() {
        let display = presenter.display(for: DomainError.server(message: "Access Denied"))

        XCTAssertEqual(display.title, "Something went wrong")
        XCTAssertEqual(display.message, "Access Denied")
    }

    func test_offline_explainsTheConnection() {
        let display = presenter.display(for: DomainError.offline)

        XCTAssertEqual(display.title, "You're offline")
        XCTAssertEqual(display.message, AppStrings.Error.offlineMessage)
    }

    func test_invalidData_hasItsOwnCopy() {
        let display = presenter.display(for: DomainError.invalidData)

        XCTAssertEqual(display.title, AppStrings.Error.invalidDataTitle)
        XCTAssertEqual(display.message, AppStrings.Error.invalidDataMessage)
    }

    func test_unknown_fallsBackToGeneric() {
        let display = presenter.display(for: DomainError.unknown)

        XCTAssertEqual(display.title, "Something went wrong")
        XCTAssertEqual(display.message, "Please try again.")
    }

    func test_nonDomainError_fallsBackToGeneric() {
        struct Unrecognised: Error {}

        let display = presenter.display(for: Unrecognised())

        XCTAssertEqual(display.title, "Something went wrong")
        XCTAssertEqual(display.message, "Please try again.")
    }
}
