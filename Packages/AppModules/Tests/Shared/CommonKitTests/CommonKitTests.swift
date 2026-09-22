import ProductDomain
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
    func test_notFound_isNotRetryable() {
        let display = ErrorPresenter().display(for: DomainError.notFound)

        XCTAssertEqual(display.title, "Product not found")
        XCTAssertFalse(display.isRetryable)
    }

    func test_offline_isRetryable() {
        XCTAssertTrue(ErrorPresenter().display(for: DomainError.offline).isRetryable)
    }

    func test_unrecognisedError_fallsBackToGeneric() {
        struct Weird: Error {}
        let display = ErrorPresenter().display(for: Weird())

        XCTAssertEqual(display.title, "Something went wrong")
        XCTAssertTrue(display.isRetryable)
    }
}

final class ProductDisplayMapperTests: XCTestCase {
    func test_carriesDescriptionThrough() {
        let product = Product(
            id: "1", name: "Apples", price: Money(minorUnits: 120),
            imageURL: nil, productDescription: "An apple a day."
        )

        let display = ProductDisplayMapper().map(product)

        XCTAssertEqual(display.id, "1")
        XCTAssertEqual(display.title, "Apples")
        XCTAssertEqual(display.description, "An apple a day.")
    }
}

/// An unresolved key comes back as the key itself, so these fail if the catalog
/// is missing from the module's bundle rather than quietly showing
/// `common.tryAgain` on screen.
final class AppStringsTests: XCTestCase {
    func test_resolvesFromTheCatalog() {
        XCTAssertEqual(AppStrings.Common.tryAgain, "Try again")
        XCTAssertEqual(AppStrings.ProductList.emptyTitle, "No products available")
        XCTAssertEqual(AppStrings.ProductDetail.descriptionUnavailable, "Description unavailable.")
    }

    func test_formatsTheInterpolatedFlowName() {
        XCTAssertEqual(AppStrings.FlowPicker.open("VIPER · UIKit"), "Open VIPER · UIKit")
    }

    func test_noStringFallsBackToItsKey() {
        let all = [
            AppStrings.Common.tryAgain, AppStrings.Common.imageUnavailable,
            AppStrings.Error.notFoundTitle, AppStrings.Error.notFoundMessage,
            AppStrings.Error.offlineTitle, AppStrings.Error.offlineMessage,
            AppStrings.Error.invalidDataTitle, AppStrings.Error.invalidDataMessage,
            AppStrings.Error.genericTitle, AppStrings.Error.genericMessage,
            AppStrings.ProductList.title, AppStrings.ProductList.emptyTitle,
            AppStrings.ProductDetail.descriptionUnavailable, AppStrings.ProductDetail.emptyTitle,
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
