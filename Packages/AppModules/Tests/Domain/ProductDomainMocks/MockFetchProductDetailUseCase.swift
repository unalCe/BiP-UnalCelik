import ProductDomain

public final class MockFetchProductDetailUseCase: FetchProductDetailUseCase, @unchecked Sendable {
    public var invokedExecute = false
    public var invokedExecuteCount = 0
    public var invokedExecuteParameters: (id: String, Void)?
    public var invokedExecuteParametersList: [(id: String, Void)] = []
    public var stubbedExecuteResult: Result<Product, Error> = .failure(MockUseCaseError.notStubbed)

    public init() {}

    public func execute(id: String) async throws -> Product {
        invokedExecute = true
        invokedExecuteCount += 1
        invokedExecuteParameters = (id, ())
        invokedExecuteParametersList.append((id, ()))
        return try stubbedExecuteResult.get()
    }
}

/// Thrown by a mock whose result the test never set.
public enum MockUseCaseError: Error, Equatable {
    case notStubbed
}
