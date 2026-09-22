import ProductDomain
import XCTest
@testable import ProductRepositoryLive

func product(
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

func makeSUT() throws -> CoreDataProductStore {
    CoreDataProductStore(container: try makeTestContainer())
}

private let anyDate = Date(timeIntervalSince1970: 1_000_000)

private func visit(_ step: Int) -> Date { anyDate.addingTimeInterval(TimeInterval(step)) }

final class CoreDataProductStoreTests: XCTestCase {
    func test_savedPage_readsBackInOrder() async throws {
        let sut = try makeSUT()
        await sut.saveListPage([product("3"), product("1"), product("6_id_is_a_string")], at: anyDate)

        let read = await sut.products()

        XCTAssertEqual(read?.value.map(\.id), ["3", "1", "6_id_is_a_string"])
    }

    func test_savedPage_carriesWhenItWasFetched() async throws {
        let sut = try makeSUT()
        await sut.saveListPage([product("1")], at: anyDate)

        let page = await sut.products()
        XCTAssertEqual(page?.fetchedAt, anyDate)
    }

    func test_noPage_readsBackAsNil() async throws {
        let sut = try makeSUT()

        let read = await sut.products()

        XCTAssertNil(read, "an empty store is not an empty page")
    }

    func test_secondPage_replacesTheFirst() async throws {
        let sut = try makeSUT()
        await sut.saveListPage([product("1"), product("2"), product("3")], at: anyDate)

        await sut.saveListPage([product("4"), product("5")], at: anyDate)

        let read = await sut.products()
        XCTAssertEqual(read?.value.map(\.id), ["4", "5"], "pages must replace, not accumulate")
    }

    func test_everyProductInThePageKeepsItsDescription() async throws {
        let sut = try makeSUT()
        let ids = (1...12).map(String.init)
        await sut.saveListPage(ids.map { product($0) }, at: anyDate)
        for (step, id) in ids.enumerated() {
            await sut.saveDetail(product(id, description: "description \(id)"), at: visit(step))
        }

        let kept = await descriptions(from: sut, ids: ids)

        XCTAssertEqual(kept, ids.map { "description \($0)" })
    }

    func test_listRefresh_doesNotWipeAFetchedDescription() async throws {
        let sut = try makeSUT()
        await sut.saveListPage([product("1")], at: anyDate)
        await sut.saveDetail(product("1", description: "An apple a day."), at: anyDate)

        await sut.saveListPage([product("1")], at: anyDate)

        let kept = await sut.detail(id: "1")
        XCTAssertEqual(kept?.value.productDescription, "An apple a day.")
    }

    func test_aProductThatLeavesThePage_isDeletedWithItsDescription() async throws {
        let sut = try makeSUT()
        await sut.saveListPage([product("1"), product("2")], at: anyDate)
        await sut.saveDetail(product("1", description: "visited"), at: anyDate)
        await sut.saveDetail(product("2", description: "kept"), at: anyDate)

        await sut.saveListPage([product("2")], at: anyDate)

        let page = await sut.products()
        let departed = await sut.detail(id: "1")
        let kept = await sut.detail(id: "2")

        XCTAssertNil(page?.value.first { $0.id == "1" }, "gone from the page")
        XCTAssertNil(departed, "and gone from the store — it is unreachable now")
        XCTAssertEqual(kept?.value.productDescription, "kept")
    }

    func test_detail_ignoresARowThatWasOnlyEverInTheList() async throws {
        let sut = try makeSUT()
        await sut.saveListPage([product("1"), product("2")], at: anyDate)

        let fromList = await sut.detail(id: "1")
        let page = await sut.products()

        XCTAssertNil(fromList, "a bare list row is not a fetched detail")
        XCTAssertNotNil(page?.value.first { $0.id == "1" }, "but it is still a product")
    }

    func test_detail_carriesWhenItWasFetched() async throws {
        let sut = try makeSUT()
        await sut.saveDetail(product("1", description: "d"), at: anyDate)

        let detail = await sut.detail(id: "1")
        XCTAssertEqual(detail?.fetchedAt, anyDate)
    }

    private func descriptions(
        from sut: CoreDataProductStore, ids: [String]
    ) async -> [String?] {
        var result: [String?] = []
        for id in ids { result.append(await sut.detail(id: id)?.value.productDescription) }
        return result
    }
}
