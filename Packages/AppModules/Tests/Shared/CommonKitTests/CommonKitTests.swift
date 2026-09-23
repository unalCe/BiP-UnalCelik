import SharedDomain
import XCTest
@testable import CommonKit

final class MoneyFormatterTests: XCTestCase {
    func test_formatsMinorUnitsAsMajorAmount() {
        let sut = MoneyFormatter(locale: Locale(identifier: "en_GB"))

        // 9 minor units is 0.09, not 9. The bug this guards against is
        // treating the integer as a major amount.
        XCTAssertTrue(sut.string(from: Money(minorUnits: 9)).contains("0.09"))
        XCTAssertTrue(sut.string(from: Money(minorUnits: 557)).contains("5.57"))
        XCTAssertTrue(sut.string(from: Money(minorUnits: 120)).contains("1.20"))
    }
}

final class ErrorPresenterTests: XCTestCase {
    func test_serverError_showsTheBackendsMessage() {
        let display = ErrorPresenter().display(for: DomainError.server(message: "Access Denied"))

        XCTAssertEqual(display.title, "Something went wrong")
        XCTAssertEqual(display.message, "Access Denied")
    }

    func test_offline_explainsTheConnection() {
        XCTAssertEqual(ErrorPresenter().display(for: DomainError.offline).title, "You're offline")
    }

    func test_unrecognisedError_fallsBackToGeneric() {
        struct Weird: Error {}
        let display = ErrorPresenter().display(for: Weird())

        XCTAssertEqual(display.title, "Something went wrong")
        XCTAssertEqual(display.message, "Please try again.")
    }
}

/// An unresolved key comes back as the key itself, so these fail if the catalog
/// is missing from the module's bundle rather than quietly showing
/// `common.tryAgain` on screen.
final class AppStringsTests: XCTestCase {
    func test_resolvesFromTheCatalog() {
        XCTAssertEqual(AppStrings.Common.tryAgain, "Try again")
        XCTAssertEqual(AppStrings.Error.offlineTitle, "You're offline")
    }

    func test_noStringFallsBackToItsKey() {
        let all = [
            AppStrings.Common.tryAgain, AppStrings.Common.imageUnavailable,
            AppStrings.Error.offlineTitle, AppStrings.Error.offlineMessage,
            AppStrings.Error.invalidDataTitle, AppStrings.Error.invalidDataMessage,
            AppStrings.Error.genericTitle, AppStrings.Error.genericMessage,
        ]
        for string in all {
            XCTAssertNil(
                string.range(of: #"^[a-z]+[A-Za-z]*\.[A-Za-z.]+"#, options: .regularExpression),
                "\(string) looks like an unresolved key"
            )
        }
    }
}
