import CommonKit
import TestSupport
import XCTest

@testable import ProductPresentation

/// An unresolved key comes back as the key itself, so these fail if the
/// catalog is missing from the module's bundle.
final class ProductStringsTests: XCTestCase {
    func test_resolvesFromTheCatalog() {
        XCTAssertEqual(AppStrings.ProductList.emptyTitle, "No products available")
        XCTAssertEqual(AppStrings.ProductDetail.descriptionUnavailable, "Description unavailable.")
    }

    func test_noStringFallsBackToItsKey() {
        XCTAssertLocalized([
            AppStrings.ProductList.title, AppStrings.ProductList.emptyTitle,
            AppStrings.ProductDetail.descriptionUnavailable, AppStrings.ProductDetail.emptyTitle,
        ])
    }
}
