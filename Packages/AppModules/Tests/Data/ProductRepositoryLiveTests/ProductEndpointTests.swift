import NetworkingKit
import XCTest

@testable import ProductRepositoryLive

final class ProductEndpointTests: XCTestCase {
    private let baseURL = URL(string: "https://example.com/developer-application-test/")!

    func test_list_resolvesAgainstTheBaseURL() throws {
        let request = try ProductEndpoint.list.makeRequest(baseURL: baseURL)

        XCTAssertEqual(request.url.absoluteString, "https://example.com/developer-application-test/cart/list")
        XCTAssertEqual(request.method, .get)
    }

    func test_detail_putsTheIDInThePath() throws {
        let request = try ProductEndpoint.detail(id: "6_id_is_a_string").makeRequest(baseURL: baseURL)

        XCTAssertEqual(request.url.path, "/developer-application-test/cart/6_id_is_a_string/detail")
    }

    /// Ids are not guaranteed to be URL-safe, so they are encoded, never
    /// interpolated raw.
    func test_detail_encodesAnUnsafeID() throws {
        let request = try ProductEndpoint.detail(id: "a b?c").makeRequest(baseURL: baseURL)

        XCTAssertEqual(request.url.path, "/developer-application-test/cart/a b?c/detail")
        XCTAssertTrue(request.url.absoluteString.contains("cart/a%20b%3Fc/detail"))
    }

    /// Always revalidate: the offline cache is Core Data's job, and a stale
    /// HTTP cache must not answer in its place.
    func test_everyEndpoint_revalidates() {
        XCTAssertEqual(ProductEndpoint.list.cachePolicy, .revalidate)
        XCTAssertEqual(ProductEndpoint.detail(id: "1").cachePolicy, .revalidate)
    }
}
