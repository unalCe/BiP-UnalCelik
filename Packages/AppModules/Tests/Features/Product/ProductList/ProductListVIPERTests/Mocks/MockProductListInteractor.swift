import ProductPresentation
@testable import ProductListVIPER

final class MockProductListInteractor: ProductListInteractorInterface, @unchecked Sendable {
    var invokedLoadProducts = false
    var invokedLoadProductsCount = 0
    var stubbedLoadProductsResult: Result<[ProductDisplayModel], Error> = .success([])

    func loadProducts() async throws -> [ProductDisplayModel] {
        invokedLoadProducts = true
        invokedLoadProductsCount += 1
        return try stubbedLoadProductsResult.get()
    }
}
