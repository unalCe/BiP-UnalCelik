import LoggingKitMocks
import NetworkingKit
import NetworkingKitMocks
import ProductDomain
import XCTest
@testable import ProductRepositoryLive

private let baseURL = URL(string: "https://example.com/developer-application-test/")!
private let tenMinutes: TimeInterval = 10 * 60

final class ProductRepositoryTests: XCTestCase {
    func test_products_decodesLivePayloadShape() async throws {
        let sut = ProductRepository(
            client: MockHTTPClient(always: .ok(HTTPFixtures.productList)),
            container: try makeTestContainer(),
            baseURL: baseURL,
            logger: SpyLogger(),
            timeToLive: tenMinutes
        )

        let products = try await sut.products()

        XCTAssertEqual(products.map(\.id), ["1", "6_id_is_a_string", "12"])
        XCTAssertEqual(products[2].price, Money(minorUnits: 9))
    }

    func test_detail_requestsEncodedPathForNonNumericID() async throws {
        let client = MockHTTPClient(always: .ok(HTTPFixtures.productDetail))
        let sut = ProductRepository(
            client: client, container: try makeTestContainer(), baseURL: baseURL,
            logger: SpyLogger(), timeToLive: tenMinutes
        )

        _ = try await sut.product(id: "6_id_is_a_string")

        XCTAssertEqual(
            client.sentRequests.first?.url.path,
            "/developer-application-test/cart/6_id_is_a_string/detail"
        )
    }

    // MARK: - Freshness

    func test_withinTimeToLive_answersFromTheDeviceWithoutAsking() async throws {
        let container = try makeTestContainer()
        let client = MockHTTPClient(always: .ok(HTTPFixtures.productList))
        let sut = ProductRepository(
            client: client, container: container, baseURL: baseURL, logger: SpyLogger(), timeToLive: tenMinutes
        )

        _ = try await sut.products()
        _ = try await sut.products()

        XCTAssertEqual(client.sentRequests.count, 1, "a fresh page must not be refetched")
    }

    func test_pastTimeToLive_goesBackToTheNetwork() async throws {
        let container = try makeTestContainer()
        let client = MockHTTPClient(always: .ok(HTTPFixtures.productList))
        let sut = ProductRepository(
            client: client, container: container, baseURL: baseURL,
            logger: SpyLogger(), timeToLive: 0
        )

        _ = try await sut.products()
        _ = try await sut.products()

        XCTAssertEqual(client.sentRequests.count, 2)
    }

    func test_pastTimeToLive_withNoNetwork_failsRatherThanShowStaleData() async throws {
        let container = try makeTestContainer()
        _ = try await ProductRepository(
            client: MockHTTPClient(always: .ok(HTTPFixtures.productList)),
            container: container, baseURL: baseURL, logger: SpyLogger(), timeToLive: tenMinutes
        ).products()

        let expired = ProductRepository(
            remote: HTTPProductRemoteDataSource(
                client: MockHTTPClient(always: .offline), baseURL: baseURL, logger: SpyLogger()
            ),
            local: CoreDataProductStore(container: container),
            logger: SpyLogger(),
            timeToLive: 0
        )

        do {
            _ = try await expired.products()
            XCTFail("expected offline")
        } catch let error as DomainError {
            XCTAssertEqual(error, .offline)
        }
    }

    func test_withinTimeToLive_withNoNetwork_stillAnswers() async throws {
        let container = try makeTestContainer()
        _ = try await ProductRepository(
            client: MockHTTPClient(always: .ok(HTTPFixtures.productList)),
            container: container, baseURL: baseURL, logger: SpyLogger(), timeToLive: tenMinutes
        ).products()

        let offline = ProductRepository(
            client: MockHTTPClient(always: .offline), container: container, baseURL: baseURL,
            logger: SpyLogger(), timeToLive: tenMinutes
        )
        let products = try await offline.products()

        XCTAssertEqual(products.map(\.id), ["1", "6_id_is_a_string", "12"])
    }

    func test_detail_withinTimeToLive_answersFromTheDevice() async throws {
        let container = try makeTestContainer()
        let client = MockHTTPClient(always: .ok(HTTPFixtures.productDetail))
        let sut = ProductRepository(
            client: client, container: container, baseURL: baseURL, logger: SpyLogger(), timeToLive: tenMinutes
        )

        _ = try await sut.product(id: "1")
        _ = try await sut.product(id: "1")

        XCTAssertEqual(client.sentRequests.count, 1)
    }

    /// Flipped deliberately: 403 means "no such product" only on detail, where
    /// S3 denies listing. On the list it is an access failure, and telling the
    /// user a product is missing would be wrong.
    func test_listRefused_withEmptyCache_throwsUnknownNotNotFound() async throws {
        let sut = ProductRepository(
            client: MockHTTPClient(always: .status(403, body: HTTPFixtures.accessDenied)),
            container: try makeTestContainer(),
            baseURL: baseURL,
            logger: SpyLogger(),
            timeToLive: tenMinutes
        )

        do {
            _ = try await sut.products()
            XCTFail("expected unknown")
        } catch let error as DomainError {
            XCTAssertEqual(error, .unknown)
        } catch {
            XCTFail("expected DomainError, got \(error)")
        }
    }

    func test_detailRefused_throwsNotFound() async throws {
        let sut = ProductRepository(
            client: MockHTTPClient(always: .status(403, body: HTTPFixtures.accessDenied)),
            container: try makeTestContainer(),
            baseURL: baseURL,
            logger: SpyLogger(),
            timeToLive: tenMinutes
        )

        do {
            _ = try await sut.product(id: "99")
            XCTFail("expected notFound")
        } catch let error as DomainError {
            XCTAssertEqual(error, .notFound)
        } catch {
            XCTFail("expected DomainError, got \(error)")
        }
    }

    func test_malformedPayload_mapsToInvalidData() async throws {
        let sut = ProductRepository(
            client: MockHTTPClient(always: .ok(HTTPFixtures.malformed)),
            container: try makeTestContainer(),
            baseURL: baseURL,
            logger: SpyLogger(),
            timeToLive: tenMinutes
        )

        do {
            _ = try await sut.products()
            XCTFail("expected invalidData")
        } catch let error as DomainError {
            XCTAssertEqual(error, .invalidData)
        } catch {
            XCTFail("expected DomainError, got \(error)")
        }
    }

    func test_emptyList_returnsEmptyRatherThanFailing() async throws {
        let sut = ProductRepository(
            client: MockHTTPClient(always: .ok(HTTPFixtures.emptyProductList)),
            container: try makeTestContainer(),
            baseURL: baseURL,
            logger: SpyLogger(),
            timeToLive: tenMinutes
        )

        let products = try await sut.products()

        XCTAssertTrue(products.isEmpty)
    }

    // MARK: - A broken cache is best-effort, never user-facing

    func test_cacheReadFailure_isAMiss_andTheNetworkAnswers() async throws {
        let logger = SpyLogger()
        let client = MockHTTPClient(always: .ok(HTTPFixtures.productList))
        let sut = ProductRepository(
            remote: HTTPProductRemoteDataSource(client: client, baseURL: baseURL, logger: logger),
            local: BrokenStore(),
            logger: logger,
            timeToLive: tenMinutes
        )

        let products = try await sut.products()

        XCTAssertEqual(products.map(\.id), ["1", "6_id_is_a_string", "12"])
        XCTAssertEqual(client.sentRequests.count, 1)
        XCTAssertTrue(
            logger.errors.contains { $0.message.contains("read failed") },
            "a failed read must not pass silently for an empty cache"
        )
    }

    func test_cacheWriteFailure_doesNotFailTheRequest() async throws {
        let logger = SpyLogger()
        let sut = ProductRepository(
            remote: HTTPProductRemoteDataSource(
                client: MockHTTPClient(always: .ok(HTTPFixtures.productDetail)),
                baseURL: baseURL, logger: logger
            ),
            local: BrokenStore(),
            logger: logger,
            timeToLive: tenMinutes
        )

        let product = try await sut.product(id: "1")

        XCTAssertEqual(product.id, "1")
        XCTAssertTrue(logger.errors.contains { $0.message.contains("write failed") })
    }

    func test_malformedPayload_logsTheDecodingCause() async throws {
        let logger = SpyLogger()
        let sut = ProductRepository(
            client: MockHTTPClient(always: .ok(HTTPFixtures.malformed)),
            container: try makeTestContainer(),
            baseURL: baseURL,
            logger: logger,
            timeToLive: tenMinutes
        )

        _ = try? await sut.products()

        XCTAssertTrue(logger.errors.contains { $0.message.contains("decoding") })
    }
}

/// Every read and write fails, the way a corrupt or full disk would.
private struct BrokenStore: ProductLocalDataSource {
    struct Failure: Error {}

    func products() async throws -> Cached<[Product]>? { throw Failure() }
    func detail(id: String) async throws -> Cached<Product>? { throw Failure() }
    func saveListPage(_ products: [Product], at date: Date) async throws { throw Failure() }
    func saveDetail(_ product: Product, at date: Date) async throws { throw Failure() }
}
