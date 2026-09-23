import AccessibilityIdentifiers
import XCTest

final class ProductListPage: Page {
    enum State {
        case loaded
        case empty
        case failed
    }

    /// The empty-state copy. Not an identifier, because the empty state's
    /// only content is this sentence; keep it in step with the string catalog.
    private static let emptyTitle = "No products available"

    lazy var collection = element(UIElements.ProductList.collection)
    lazy var retryButton = element(UIElements.StateView.retryButton)
    lazy var emptyMessage = app.staticTexts[Self.emptyTitle]

    /// Waits until the screen is in `state`, so a test never acts on a list
    /// that is still loading.
    init(state: State = .loaded, file: StaticString = #filePath, line: UInt = #line) {
        super.init()
        switch state {
        case .loaded: expect(collection, .exists, file: file, line: line)
        case .empty: expect(emptyMessage, .exists, file: file, line: line)
        case .failed: expect(retryButton, .hittable, file: file, line: line)
        }
    }

    func cell(productID: String) -> XCUIElement {
        element(UIElements.ProductList.cell, suffix: productID)
    }

    // MARK: - Checks

    @discardableResult
    func expectProducts(_ ids: [String], file: StaticString = #filePath, line: UInt = #line) -> Self {
        ids.forEach { expect(cell(productID: $0), .exists, file: file, line: line) }
        return self
    }

    // MARK: - Actions

    @discardableResult
    func tapProduct(id: String, file: StaticString = #filePath, line: UInt = #line) -> ProductDetailPage {
        expect(cell(productID: id), .hittable, file: file, line: line).tap()
        return ProductDetailPage(file: file, line: line)
    }

    @discardableResult
    func tapRetry(file: StaticString = #filePath, line: UInt = #line) -> ProductListPage {
        expect(retryButton, .hittable, file: file, line: line).tap()
        return ProductListPage(state: .loaded, file: file, line: line)
    }
}
