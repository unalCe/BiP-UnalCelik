import ProductPresentation
@testable import ProductDetailVIPER

final class MockProductDetailInteractor: ProductDetailInteractorInterface, @unchecked Sendable {
    var invokedLoadProduct = false
    var invokedLoadProductCount = 0
    var invokedLoadProductParameters: (id: String, Void)?
    var invokedLoadProductParametersList: [(id: String, Void)] = []
    var stubbedLoadProductResult: Result<ProductDisplayModel, Error>!

    func loadProduct(id: String) async throws -> ProductDisplayModel {
        invokedLoadProduct = true
        invokedLoadProductCount += 1
        invokedLoadProductParameters = (id, ())
        invokedLoadProductParametersList.append((id, ()))
        return try stubbedLoadProductResult.get()
    }
}
