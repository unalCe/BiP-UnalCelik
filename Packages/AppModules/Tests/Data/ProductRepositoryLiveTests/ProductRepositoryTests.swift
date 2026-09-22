import NetworkingKit
import NetworkingKitMocks
import ProductDomain
import XCTest
@testable import ProductRepositoryLive

private let baseURL = URL(string: "https://example.com/developer-application-test/")!

final class ProductRepositoryTests: XCTestCase {
    func test_products_decodesLivePayloadShape() async throws {
        let sut = ProductRepository(
            client: MockHTTPClient(always: .ok(HTTPFixtures.productList)),
            container: try makeTestContainer(),
            baseURL: baseURL
        )

        let products = try await sut.products()

        XCTAssertEqual(products.map(\.id), ["1", "6_id_is_a_string", "12"])
        XCTAssertEqual(products[2].price, Money(minorUnits: 9))
    }

    func test_detail_requestsEncodedPathForNonNumericID() async throws {
        let client = MockHTTPClient(always: .ok(HTTPFixtures.productDetail))
        let sut = ProductRepository(client: client, container: try makeTestContainer(), baseURL: baseURL)

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
        let sut = ProductRepository(client: client, container: container, baseURL: baseURL)

        _ = try await sut.products()
        _ = try await sut.products()

        XCTAssertEqual(client.sentRequests.count, 1, "a fresh page must not be refetched")
    }

    func test_pastTimeToLive_goesBackToTheNetwork() async throws {
        let container = try makeTestContainer()
        let client = MockHTTPClient(always: .ok(HTTPFixtures.productList))
        let sut = ProductRepository(
            client: client, container: container, baseURL: baseURL, timeToLive: 0
        )

        _ = try await sut.products()
        _ = try await sut.products()

        XCTAssertEqual(client.sentRequests.count, 2)
    }

    func test_pastTimeToLive_withNoNetwork_failsRatherThanShowStaleData() async throws {
        let container = try makeTestContainer()
        _ = try await ProductRepository(
            client: MockHTTPClient(always: .ok(HTTPFixtures.productList)),
            container: container, baseURL: baseURL
        ).products()

        let expired = ProductRepository(
            remote: HTTPProductRemoteDataSource(
                client: MockHTTPClient(always: .offline), baseURL: baseURL
            ),
            local: CoreDataProductStore(container: container),
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
            container: container, baseURL: baseURL
        ).products()

        let offline = ProductRepository(
            client: MockHTTPClient(always: .offline), container: container, baseURL: baseURL
        )
        let products = try await offline.products()

        XCTAssertEqual(products.map(\.id), ["1", "6_id_is_a_string", "12"])
    }

    func test_detail_withinTimeToLive_answersFromTheDevice() async throws {
        let container = try makeTestContainer()
        let client = MockHTTPClient(always: .ok(HTTPFixtures.productDetail))
        let sut = ProductRepository(client: client, container: container, baseURL: baseURL)

        _ = try await sut.product(id: "1")
        _ = try await sut.product(id: "1")

        XCTAssertEqual(client.sentRequests.count, 1)
    }

    func test_networkFailure_withEmptyCache_throwsMappedError() async throws {
        let sut = ProductRepository(
            client: MockHTTPClient(always: .status(403, body: HTTPFixtures.accessDenied)),
            container: try makeTestContainer(),
            baseURL: baseURL
        )

        do {
            _ = try await sut.products()
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
            baseURL: baseURL
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
            baseURL: baseURL
        )

        let products = try await sut.products()

        XCTAssertTrue(products.isEmpty)
    }
}
