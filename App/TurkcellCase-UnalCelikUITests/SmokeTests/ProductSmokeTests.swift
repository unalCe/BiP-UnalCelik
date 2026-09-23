import XCTest

/// One journey per presentation stack: the app launches, lists the products,
/// opens one and comes back. Proves each stack is wired end to end; behaviour
/// in depth belongs to the unit tests and, later, the regression suite.
final class ProductSmokeTests: BaseUITest {
    private let productIDs = ["1", "6_id_is_a_string", "12"]

    func test_smoke_mvvmUIKit_listToDetailAndBack() throws {
        try launch(.productsLoaded, flow: .mvvmUIKit)

        listToDetailAndBack()
    }

    func test_smoke_mvvmSwiftUI_listToDetailAndBack() throws {
        try launch(.productsLoaded, flow: .mvvmSwiftUI)

        listToDetailAndBack()
    }

    func test_smoke_viperUIKit_listToDetailAndBack() throws {
        try launch(.productsLoaded, flow: .viperUIKit)

        listToDetailAndBack()
    }

    func test_smoke_offline_retryLoadsTheProducts() throws {
        try launch(.offlineThenLoaded)

        ProductListPage(state: .failed)
            .tapRetry()
            .expectProducts(productIDs)
    }

    func test_smoke_emptyResponse_showsTheEmptyState() throws {
        try launch(.emptyList)

        check(page: ProductListPage(state: .empty))
    }

    // MARK: - Journeys

    private func listToDetailAndBack(file: StaticString = #filePath, line: UInt = #line) {
        ProductListPage(file: file, line: line)
            .expectProducts(productIDs, file: file, line: line)
            .tapProduct(id: "1", file: file, line: line)
            .expectProduct(
                title: "Apples",
                price: "$1.20",
                description: "An apple a day keeps the doctor away.",
                file: file, line: line
            )
            .tapBack(file: file, line: line)
            .expectProducts(productIDs, file: file, line: line)
    }
}
