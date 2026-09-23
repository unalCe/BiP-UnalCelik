import DependencyEngine
import LoggingKit
import LoggingKitMocks
import NetworkingKit
import NetworkingKitMocks
import PersistenceKit
import ProductDomain
import XCTest
@testable import ProductRepositoryLive

final class ProductRepositoryDependencyRegistrationTests: XCTestCase {
    func test_registeredRepository_usesTheGivenBaseURLAndTimeToLive() async throws {
        let engine = DependencyEngine()
        let client = MockHTTPClient(always: .ok(HTTPFixtures.productList))
        engine.register(value: client as HTTPClientInterface, for: HTTPClientInterface.self)
        let container: PersistentContainerInterface = try makeTestContainer()
        engine.register(value: container, for: PersistentContainerInterface.self)
        engine.register(value: SpyLogger() as LoggerInterface, for: LoggerInterface.self)

        ProductRepositoryDependencyRegistration.register(
            to: engine,
            baseURL: URL(string: "https://example.org/elsewhere/")!,
            timeToLive: 0
        )
        let sut: ProductRepositoryInterface? = engine.resolve(ProductRepositoryInterface.self)
        _ = try await sut?.products()
        _ = try await sut?.products()

        XCTAssertEqual(client.sentRequests.first?.url.host, "example.org")
        XCTAssertEqual(client.sentRequests.first?.url.path, "/elsewhere/cart/list")
        XCTAssertEqual(client.sentRequests.count, 2, "a zero window must not answer from the device")
    }
}
