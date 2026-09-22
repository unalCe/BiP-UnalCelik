import XCTest
@testable import ProductDomain

final class MoneyTests: XCTestCase {
    func test_holdsMinorUnitsExactly() {
        XCTAssertEqual(Money(minorUnits: 9).minorUnits, 9)
        XCTAssertEqual(Money(minorUnits: 557).minorUnits, 557)
    }
}

final class ProductTests: XCTestCase {
    /// Guards the live payload's non-numeric id. An `Int` here drops a product.
    func test_idIsAString() {
        let product = Product(
            id: "6_id_is_a_string",
            name: "Pork",
            price: Money(minorUnits: 343),
            imageURL: nil
        )
        XCTAssertEqual(product.id, "6_id_is_a_string")
    }
}

final class FetchProductsUseCaseTests: XCTestCase {
    func test_execute_forwardsRepositoryResult() async throws {
        let expected = [
            Product(id: "1", name: "Apples", price: Money(minorUnits: 120), imageURL: nil)
        ]
        let sut = FetchProducts(repository: StubRepository(products: expected))

        let result = try await sut.execute()

        XCTAssertEqual(result, expected)
    }

    func test_executeDetail_propagatesNotFound() async {
        let sut = FetchProductDetail(repository: StubRepository(products: []))

        do {
            _ = try await sut.execute(id: "absent")
            XCTFail("expected notFound")
        } catch let error as DomainError {
            XCTAssertEqual(error, .notFound)
        } catch {
            XCTFail("expected DomainError, got \(error)")
        }
    }
}

private struct StubRepository: ProductRepositoryInterface {
    let products: [Product]

    func products() async throws -> [Product] { products }

    func product(id: String) async throws -> Product {
        guard let match = products.first(where: { $0.id == id }) else {
            throw DomainError.notFound
        }
        return match
    }

    func cachedDetail(id: String) async -> Product? {
        products.first { $0.id == id }
    }
}
