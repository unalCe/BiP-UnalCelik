import ProductDomain

public final class MockProductRepository: ProductRepositoryInterface, @unchecked Sendable {
    public var invokedProducts = false
    public var invokedProductsCount = 0
    public var stubbedProductsResult: Result<[Product], Error> = .success([])

    public var invokedProduct = false
    public var invokedProductCount = 0
    public var invokedProductParameters: (id: String, Void)?
    public var invokedProductParametersList: [(id: String, Void)] = []
    public var stubbedProductResult: Result<Product, Error> = .failure(MockRepositoryError.notStubbed)

    public init() {}

    public func products() async throws -> [Product] {
        invokedProducts = true
        invokedProductsCount += 1
        return try stubbedProductsResult.get()
    }

    public func product(id: String) async throws -> Product {
        invokedProduct = true
        invokedProductCount += 1
        invokedProductParameters = (id, ())
        invokedProductParametersList.append((id, ()))
        return try stubbedProductResult.get()
    }
}

/// Thrown by the mock when the test never set a result.
public enum MockRepositoryError: Error, Equatable {
    case notStubbed
}
