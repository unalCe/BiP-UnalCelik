import CommonKit
import ProductDomain
import SharedDomain
import XCTest
@testable import ProductPresentation

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

final class ProductStringsTests: XCTestCase {
    func test_resolvesFromTheCatalog() {
        XCTAssertEqual(AppStrings.ProductList.emptyTitle, "No products available")
        XCTAssertEqual(AppStrings.ProductDetail.descriptionUnavailable, "Description unavailable.")
    }

    func test_noStringFallsBackToItsKey() {
        let all = [
            AppStrings.ProductList.title, AppStrings.ProductList.emptyTitle,
            AppStrings.ProductDetail.descriptionUnavailable, AppStrings.ProductDetail.emptyTitle,
        ]
        for string in all {
            XCTAssertNil(
                string.range(of: #"^[a-z]+[A-Za-z]*\.[A-Za-z.]+"#, options: .regularExpression),
                "\(string) looks like an unresolved key"
            )
        }
    }
}
