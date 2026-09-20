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
