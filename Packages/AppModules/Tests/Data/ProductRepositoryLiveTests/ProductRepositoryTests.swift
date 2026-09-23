import CachingKit
import LoggingKitMocks
import NetworkingKit
import NetworkingKitMocks
import PersistenceKitLive
import ProductDomain
import ProductRepositoryMocks
import SharedDomain
import TestSupport
import XCTest

@testable import ProductRepositoryLive

/// The real repository over a mock HTTP client and an in-memory Core Data
/// store. Responses are the captured JSON fixtures, so decoding, mapping,
/// caching and error mapping all run as they do in the app.
final class ProductRepositoryTests: XCTestCase {
    private var repository: ProductRepository!
    private var client: MockHTTPClient!
    private var container: CoreDataStack!
    private var logger: SpyLogger!
    private var clock: TestClock!

    private let baseURL = URL(string: "https://example.com/developer-application-test/")!
    private let timeToLive: TimeInterval = 10 * 60

    override func setUpWithError() throws {
        try super.setUpWithError()
        container = try makeTestContainer()
        clock = TestClock()
        reCreate()
    }

    override func tearDown() {
        repository = nil
        client = nil
        container = nil
        logger = nil
        clock = nil
        super.tearDown()
    }

    /// Rebuilds the repository over the same store and clock, so a test can
    /// fill the cache with one client and read it back with another.
    private func reCreate(
        response: MockHTTPClient.Behaviour = .ok(ProductFixture.data("ProductListResponse")),
        local: ProductLocalDataSource? = nil
    ) {
        client = MockHTTPClient(always: response)
        logger = SpyLogger()
        repository = ProductRepository(
            remote: HTTPProductRemoteDataSource(apiClient: APIClient(baseURL: baseURL, transport: client)),
            local: local ?? CoreDataProductStore(container: container),
            logger: logger,
            timeToLive: timeToLive,
            now: { [clock] in clock!.now }
        )
    }

    // MARK: - products

    func test_products_decodesTheListPayload() async throws {
        let products = try await repository.products()

        XCTAssertEqual(products, ProductFixture.list())
        XCTAssertEqual(client.sentRequests.map(\.url.path), ["/developer-application-test/cart/list"])
    }

    func test_products_emptyList_returnsEmptyRatherThanFailing() async throws {
        reCreate(response: .ok(ProductFixture.data("EmptyProductListResponse")))

        let products = try await repository.products()

        XCTAssertTrue(products.isEmpty)
    }

    func test_products_refused_surfacesTheBackendsMessage() async {
        reCreate(response: .status(403, body: ProductFixture.data("AccessDenied", extension: "xml")))

        await XCTAssertThrowsErrorAsync(
            try await repository.products(), equals: DomainError.server(message: "Access Denied")
        )
    }

    func test_products_malformedPayload_isInvalidDataAndLogsTheCause() async {
        reCreate(response: .ok(ProductFixture.data("MalformedProductListResponse")))

        await XCTAssertThrowsErrorAsync(try await repository.products(), equals: DomainError.invalidData)
        XCTAssertTrue(logger.errors.contains { $0.message.contains("decoding") })
    }

    func test_products_offlineWithNothingCached_isOffline() async {
        reCreate(response: .offline)

        await XCTAssertThrowsErrorAsync(try await repository.products(), equals: DomainError.offline)
    }

    // MARK: - product(id:)

    func test_product_requestsAnEncodedPathForANonNumericID() async throws {
        reCreate(response: .ok(ProductFixture.data("ProductDetailResponse")))

        _ = try await repository.product(id: "6_id_is_a_string")

        XCTAssertEqual(client.sentRequests.first?.url.path,
                       "/developer-application-test/cart/6_id_is_a_string/detail")
    }

    func test_product_decodesTheDetailPayload() async throws {
        reCreate(response: .ok(ProductFixture.data("ProductDetailResponse")))

        let product = try await repository.product(id: "1")

        XCTAssertEqual(product, ProductFixture.detail())
    }

    func test_product_refused_surfacesTheBackendsMessage() async {
        reCreate(response: .status(403, body: ProductFixture.data("AccessDenied", extension: "xml")))

        await XCTAssertThrowsErrorAsync(
            try await repository.product(id: "99"), equals: DomainError.server(message: "Access Denied")
        )
    }

    // MARK: - Freshness

    func test_withinTimeToLive_answersFromTheDeviceWithoutAsking() async throws {
        _ = try await repository.products()
        clock.advance(by: timeToLive - 1)

        _ = try await repository.products()

        XCTAssertEqual(client.sentRequests.count, 1, "a fresh page must not be refetched")
    }

    func test_pastTimeToLive_goesBackToTheNetwork() async throws {
        _ = try await repository.products()
        clock.advance(by: timeToLive)

        _ = try await repository.products()

        XCTAssertEqual(client.sentRequests.count, 2)
    }

    func test_withinTimeToLive_offline_stillAnswersFromTheDevice() async throws {
        _ = try await repository.products()
        reCreate(response: .offline)

        let products = try await repository.products()

        XCTAssertEqual(products, ProductFixture.list())
    }

    func test_pastTimeToLive_offline_failsRatherThanShowStaleData() async throws {
        _ = try await repository.products()
        clock.advance(by: timeToLive)
        reCreate(response: .offline)

        await XCTAssertThrowsErrorAsync(try await repository.products(), equals: DomainError.offline)
    }

    func test_detail_withinTimeToLive_answersFromTheDevice() async throws {
        reCreate(response: .ok(ProductFixture.data("ProductDetailResponse")))
        _ = try await repository.product(id: "1")

        _ = try await repository.product(id: "1")

        XCTAssertEqual(client.sentRequests.count, 1)
    }

    // MARK: - A broken cache is best-effort, never user-facing

    func test_cacheReadFailure_isAMiss_andTheNetworkAnswers() async throws {
        reCreate(local: BrokenStore())

        let products = try await repository.products()

        XCTAssertEqual(products, ProductFixture.list())
        XCTAssertEqual(client.sentRequests.count, 1)
        XCTAssertTrue(logger.errors.contains { $0.message.contains("read failed") },
                      "a failed read must not pass silently for an empty cache")
    }

    func test_cacheWriteFailure_doesNotFailTheRequest() async throws {
        reCreate(response: .ok(ProductFixture.data("ProductDetailResponse")), local: BrokenStore())

        let product = try await repository.product(id: "1")

        XCTAssertEqual(product.id, "1")
        XCTAssertTrue(logger.errors.contains { $0.message.contains("write failed") })
    }
}

/// Every read and write fails, the way a corrupt or full disk would.
private struct BrokenStore: ProductLocalDataSource {
    struct Failure: Error {}

    func products() async throws -> CacheEntry<[Product]>? { throw Failure() }
    func detail(id: String) async throws -> CacheEntry<Product>? { throw Failure() }
    func saveListPage(_ products: [Product], at date: Date) async throws { throw Failure() }
    func saveDetail(_ product: Product, at date: Date) async throws { throw Failure() }
}

/// Time the test moves by hand, so freshness is decided without sleeping.
private final class TestClock: @unchecked Sendable {
    private(set) var now = Date(timeIntervalSince1970: 1_000_000)

    func advance(by interval: TimeInterval) { now += interval }
}
