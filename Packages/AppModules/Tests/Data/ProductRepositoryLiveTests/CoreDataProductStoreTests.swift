import CoreData
import PersistenceKit
import PersistenceKitLive
import ProductDomain
import SharedDomain
import TestSupport
import XCTest

@testable import ProductRepositoryLive

final class CoreDataProductStoreTests: XCTestCase {
    private var store: CoreDataProductStore!

    private let anyDate = Date(timeIntervalSince1970: 1_000_000)

    override func setUpWithError() throws {
        try super.setUpWithError()
        store = CoreDataProductStore(container: try makeTestContainer())
    }

    override func tearDown() {
        store = nil
        super.tearDown()
    }

    func test_savedPage_readsBackInOrder() async throws {
        try await store.saveListPage([product("3"), product("1"), product("6_id_is_a_string")], at: anyDate)

        let read = try await store.products()

        XCTAssertEqual(read?.value.map(\.id), ["3", "1", "6_id_is_a_string"])
    }

    func test_savedPage_carriesWhenItWasFetched() async throws {
        try await store.saveListPage([product("1")], at: anyDate)

        let page = try await store.products()
        XCTAssertEqual(page?.fetchedAt, anyDate)
    }

    func test_noPage_readsBackAsNil() async throws {
        let read = try await store.products()

        XCTAssertNil(read, "an empty store is not an empty page")
    }

    func test_secondPage_replacesTheFirst() async throws {
        try await store.saveListPage([product("1"), product("2"), product("3")], at: anyDate)

        try await store.saveListPage([product("4"), product("5")], at: anyDate)

        let read = try await store.products()
        XCTAssertEqual(read?.value.map(\.id), ["4", "5"], "pages must replace, not accumulate")
    }

    func test_everyProductInThePageKeepsItsDescription() async throws {
        let ids = (1...12).map(String.init)
        try await store.saveListPage(ids.map { product($0) }, at: anyDate)
        for (step, id) in ids.enumerated() {
            try await store.saveDetail(product(id, description: "description \(id)"), at: visit(step))
        }

        let kept = try await descriptions(from: store, ids: ids)

        XCTAssertEqual(kept, ids.map { "description \($0)" })
    }

    func test_listRefresh_doesNotWipeAFetchedDescription() async throws {
        try await store.saveListPage([product("1")], at: anyDate)
        try await store.saveDetail(product("1", description: "An apple a day."), at: anyDate)

        try await store.saveListPage([product("1")], at: anyDate)

        let kept = try await store.detail(id: "1")
        XCTAssertEqual(kept?.value.productDescription, "An apple a day.")
    }

    func test_aProductThatLeavesThePage_isDeletedWithItsDescription() async throws {
        try await store.saveListPage([product("1"), product("2")], at: anyDate)
        try await store.saveDetail(product("1", description: "visited"), at: anyDate)
        try await store.saveDetail(product("2", description: "kept"), at: anyDate)

        try await store.saveListPage([product("2")], at: anyDate)

        let page = try await store.products()
        let departed = try await store.detail(id: "1")
        let kept = try await store.detail(id: "2")

        XCTAssertNil(page?.value.first { $0.id == "1" }, "gone from the page")
        XCTAssertNil(departed, "and gone from the store — it is unreachable now")
        XCTAssertEqual(kept?.value.productDescription, "kept")
    }

    func test_detail_ignoresARowThatWasOnlyEverInTheList() async throws {
        try await store.saveListPage([product("1"), product("2")], at: anyDate)

        let fromList = try await store.detail(id: "1")
        let page = try await store.products()

        XCTAssertNil(fromList, "a bare list row is not a fetched detail")
        XCTAssertNotNil(page?.value.first { $0.id == "1" }, "but it is still a product")
    }

    func test_detail_carriesWhenItWasFetched() async throws {
        try await store.saveDetail(product("1", description: "d"), at: anyDate)

        let detail = try await store.detail(id: "1")
        XCTAssertEqual(detail?.fetchedAt, anyDate)
    }

    /// The API sends no currency and the store has no default, so a row can
    /// only ever hold what the domain gave it.
    func test_currency_readsBackAsTheDomainGaveIt() async throws {
        let euros = Product(id: "1", name: "Apples", price: Money(minorUnits: 120, currencyCode: "EUR"), imageURL: nil)
        try await store.saveListPage([euros], at: anyDate)
        try await store.saveDetail(euros, at: anyDate)

        let listed = try await store.products()?.value.first?.price
        let detailed = try await store.detail(id: "1")?.value.price

        XCTAssertEqual(listed, euros.price)
        XCTAssertEqual(detailed, euros.price)
    }

    /// A model without `CDProduct` used to trap on a force-unwrap; it has to
    /// arrive as an error the repository can absorb.
    func test_modelWithoutTheEntity_throwsRatherThanTrapping() async throws {
        let unrelated = NSEntityDescription()
        unrelated.name = "Unrelated"
        let model = NSManagedObjectModel()
        model.entities = [unrelated]
        store = CoreDataProductStore(
            container: try CoreDataStack(modelName: "Unrelated", model: model, inMemory: true)
        )

        await XCTAssertThrowsErrorAsync(try await store.saveDetail(product("1"), at: anyDate)) { error in
            guard case PersistenceError.writeFailed(let underlying) = error,
                  case PersistenceError.entityNotFound(let name)? = underlying as? PersistenceError
            else { return XCTFail("expected writeFailed(entityNotFound), got \(error)") }
            XCTAssertEqual(name, "CDProduct")
        }
    }

    // MARK: - Helpers

    private func descriptions(
        from store: CoreDataProductStore, ids: [String]
    ) async throws -> [String?] {
        var result: [String?] = []
        for id in ids { result.append(try await store.detail(id: id)?.value.productDescription) }
        return result
    }

    private func visit(_ step: Int) -> Date { anyDate.addingTimeInterval(TimeInterval(step)) }

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
}
