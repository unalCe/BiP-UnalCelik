import ProductDomain
import XCTest
@testable import ProductRepositoryLive

private func product(
    _ id: String, name: String? = nil, price: Int = 100, description: String? = nil
) -> Product {
    Product(
        id: id,
        name: name ?? "Product \(id)",
        price: Money(minorUnits: price),
        imageURL: URL(string: "https://example.com/\(id).jpg"),
        productDescription: description
    )
}

private func makeSUT() throws -> CoreDataProductStore {
    CoreDataProductStore(container: try makeTestContainer())
}

final class CoreDataProductStoreTests: XCTestCase {
    func test_savedPage_readsBackInOrder() async throws {
        let sut = try makeSUT()
        await sut.saveListPage([product("3"), product("1"), product("6_id_is_a_string")])

        let read = await sut.products()

        XCTAssertEqual(read.map(\.id), ["3", "1", "6_id_is_a_string"])
    }

    func test_secondPage_replacesTheFirst() async throws {
        let sut = try makeSUT()
        await sut.saveListPage([product("1"), product("2"), product("3")])

        await sut.saveListPage([product("4"), product("5")])

        let read = await sut.products()
        XCTAssertEqual(read.map(\.id), ["4", "5"], "pages must replace, not accumulate")
    }

    func test_onlyTheLastThreeDetailsKeepTheirDescription() async throws {
        let sut = try makeSUT()
        for id in ["1", "2", "3", "4"] {
            await sut.saveDetail(product(id, description: "description \(id)"))
        }

        let descriptions = await descriptions(from: sut, ids: ["1", "2", "3", "4"])

        XCTAssertEqual(descriptions["4"], "description 4")
        XCTAssertEqual(descriptions["3"], "description 3")
        XCTAssertEqual(descriptions["2"], "description 2")
        XCTAssertNil(descriptions["1"] ?? nil, "the fourth-most-recent detail must be evicted")
    }

    func test_evictedDetail_keepsItsListRow() async throws {
        let sut = try makeSUT()
        await sut.saveListPage((1...4).map { product("\($0)") })
        for id in ["1", "2", "3", "4"] {
            await sut.saveDetail(product(id, description: "description \(id)"))
        }

        let evicted = await sut.product(id: "1")

        XCTAssertEqual(evicted?.name, "Product 1", "eviction drops the detail, not the product")
        XCTAssertEqual(evicted?.price, Money(minorUnits: 100))
        XCTAssertNotNil(evicted?.imageURL)
        XCTAssertNil(evicted?.productDescription)
        let page = await sut.products()
        XCTAssertEqual(page.map(\.id), ["1", "2", "3", "4"])
    }

    func test_listRefresh_doesNotWipeAFetchedDescription() async throws {
        let sut = try makeSUT()
        await sut.saveListPage([product("1")])
        await sut.saveDetail(product("1", description: "An apple a day."))

        // the list endpoint sends no description at all
        await sut.saveListPage([product("1")])

        let read = await sut.product(id: "1")
        XCTAssertEqual(read?.productDescription, "An apple a day.")
    }

    func test_aProductInNeitherRole_isDeleted() async throws {
        let sut = try makeSUT()
        await sut.saveListPage([product("1"), product("2")])
        await sut.saveDetail(product("2", description: "kept"))

        // "1" leaves the page and was never visited
        await sut.saveListPage([product("2")])

        let orphan = await sut.product(id: "1")
        let kept = await sut.product(id: "2")
        XCTAssertNil(orphan, "a row in neither the page nor the retained details must not leak")
        XCTAssertEqual(kept?.productDescription, "kept")
    }

    private func descriptions(
        from sut: CoreDataProductStore, ids: [String]
    ) async -> [String: String?] {
        var result: [String: String?] = [:]
        for id in ids { result[id] = await sut.product(id: id)?.productDescription }
        return result
    }
}
