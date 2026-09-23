import Foundation
import ProductDomain
import SharedDomain

public final class StubProductRepository: ProductRepositoryInterface, @unchecked Sendable {
    private let listResult: Result<[Product], Error>
    private let detailResult: Result<Product, Error>?

    private let lock = NSLock()
    private var requestedIDs: [String] = []

    // MARK: - Public Funcs

    public var requestedProductIDs: [String] { lock.withLock { requestedIDs } }

    // MARK: - Lifecycle

    public init(
        products: Result<[Product], Error> = .success(Product.fixtures),
        detail: Result<Product, Error>? = nil
    ) {
        self.listResult = products
        self.detailResult = detail
    }

    public func products() async throws -> [Product] {
        try listResult.get()
    }

    public func product(id: String) async throws -> Product {
        lock.withLock { requestedIDs.append(id) }
        if let detailResult { return try detailResult.get() }
        guard let match = try listResult.get().first(where: { $0.id == id }) else {
            throw DomainError.unknown
        }
        return match
    }
}

public extension Product {
    /// Mirrors the live payload, non-numeric id included.
    static let fixtures: [Product] = [
        Product(id: "1", name: "Apples", price: Money(minorUnits: 120),
                imageURL: URL(string: "https://example.com/1.jpg")),
        Product(id: "6_id_is_a_string", name: "Pork", price: Money(minorUnits: 343),
                imageURL: URL(string: "https://example.com/6.jpg")),
        Product(id: "12", name: "Peppers", price: Money(minorUnits: 9),
                imageURL: URL(string: "https://example.com/12.jpg")),
    ]

    static func fixture(
        id: String = "1",
        name: String = "Apples",
        minorUnits: Int = 120,
        description: String? = nil
    ) -> Product {
        Product(id: id, name: name, price: Money(minorUnits: minorUnits),
                imageURL: nil, productDescription: description)
    }
}
