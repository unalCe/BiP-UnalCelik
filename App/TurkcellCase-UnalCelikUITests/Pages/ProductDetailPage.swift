import AccessibilityIdentifiers
import XCTest

final class ProductDetailPage: Page {
    lazy var image = element(UIElements.ProductDetail.image)
    lazy var title = element(UIElements.ProductDetail.title)
    lazy var price = element(UIElements.ProductDetail.price)
    lazy var productDescription = element(UIElements.ProductDetail.description)
    lazy var backButton = app.navigationBars.buttons.element(boundBy: 0)

    /// Waits until the product has loaded.
    init(file: StaticString = #filePath, line: UInt = #line) {
        super.init()
        expect(title, .exists, file: file, line: line)
    }

    // MARK: - Checks

    /// Every component of the screen is there, showing this product.
    @discardableResult
    func expectProduct(
        title expectedTitle: String,
        price expectedPrice: String,
        description expectedDescription: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> Self {
        expect(image, .exists, file: file, line: line)
        expect(title, .labelEquals(expectedTitle), file: file, line: line)
        expect(price, .labelEquals(expectedPrice), file: file, line: line)
        expect(productDescription, .labelEquals(expectedDescription), file: file, line: line)
        return self
    }

    // MARK: - Actions

    @discardableResult
    func tapBack(file: StaticString = #filePath, line: UInt = #line) -> ProductListPage {
        expect(backButton, .hittable, file: file, line: line).tap()
        return ProductListPage(state: .loaded, file: file, line: line)
    }
}
