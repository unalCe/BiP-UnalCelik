import Foundation
import NetworkingKit
import NetworkingKitMocks
import TestSupport
import XCTest

final class APIClientTests: XCTestCase {
    private var client: APIClient!
    private var transport: MockHTTPClient!

    private let baseURL = URL(string: "https://example.com/api/")!
    private let apple = Data(#"{"name":"Apple"}"#.utf8)

    override func setUp() {
        super.setUp()
        reCreate()
    }

    override func tearDown() {
        client = nil
        transport = nil
        super.tearDown()
    }

    private func reCreate(
        response: MockHTTPClient.Behaviour? = nil,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        transport = MockHTTPClient(always: response ?? .ok(apple))
        client = APIClient(baseURL: baseURL, transport: transport, decoder: decoder)
    }

    func test_execute_decodesASuccessfulResponse() async throws {
        let item = try await client.execute(Path("item"), as: Item.self)

        XCTAssertEqual(item, Item(name: "Apple"))
    }

    func test_execute_sendsTheEndpointResolvedAgainstTheBaseURL() async throws {
        _ = try await client.execute(Path("cart/list"), as: Item.self)

        XCTAssertEqual(transport.sentRequests.map(\.url.absoluteString), ["https://example.com/api/cart/list"])
    }

    func test_execute_usesTheInjectedDecoder() async throws {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        reCreate(response: .ok(Data(#"{"product_name":"Apple"}"#.utf8)), decoder: decoder)

        let item = try await client.execute(Path("item"), as: SnakeItem.self)

        XCTAssertEqual(item.productName, "Apple")
    }

    func test_malformedBody_throwsDecodingWithTheUnderlyingCause() async {
        reCreate(response: .ok(Data(#"{"title":"Apple"}"#.utf8)))

        await XCTAssertThrowsErrorAsync(try await client.execute(Path("item"), as: Item.self)) { error in
            guard case NetworkError.decoding(let underlying) = error else {
                return XCTFail("expected NetworkError.decoding, got \(error)")
            }
            XCTAssertTrue(underlying is DecodingError)
        }
    }

    func test_statusFailure_passesThroughIntact() async {
        let body = Data("denied".utf8)
        reCreate(response: .status(403, body: body))

        await XCTAssertThrowsErrorAsync(try await client.execute(Path("item"), as: Item.self)) { error in
            guard case NetworkError.unacceptableStatus(let code, let received) = error else {
                return XCTFail("expected NetworkError.unacceptableStatus, got \(error)")
            }
            XCTAssertEqual(code, 403)
            XCTAssertEqual(received, body)
        }
    }

    func test_transportFailure_passesThroughIntact() async {
        reCreate(response: .offline)

        await XCTAssertThrowsErrorAsync(try await client.execute(Path("item"), as: Item.self)) { error in
            XCTAssertEqual((error as? NetworkError)?.isOffline, true, "got \(error)")
        }
    }

    func test_unbuildableURL_throwsInvalidURLWithoutSending() async {
        await XCTAssertThrowsErrorAsync(try await client.execute(Path("http://[::1"), as: Item.self)) { error in
            guard case NetworkError.invalidURL = error else {
                return XCTFail("expected NetworkError.invalidURL, got \(error)")
            }
        }
        XCTAssertEqual(transport.sendCount, 0)
    }
}

private struct Path: Endpoint {
    let path: String
    init(_ path: String) { self.path = path }
}

private struct Item: Decodable, Equatable {
    let name: String
}

private struct SnakeItem: Decodable {
    let productName: String
}
