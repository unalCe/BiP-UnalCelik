import ProductDomain

public final class MockFetchProductsUseCase: FetchProductsUseCase, @unchecked Sendable {
    public var invokedExecute = false
    public var invokedExecuteCount = 0
    public var stubbedExecuteResult: Result<[Product], Error> = .success([])

    public init() {}

    public func execute() async throws -> [Product] {
        invokedExecute = true
        invokedExecuteCount += 1
        return try stubbedExecuteResult.get()
    }
}
