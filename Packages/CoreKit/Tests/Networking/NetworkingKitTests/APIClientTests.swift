import Foundation
import NetworkingKit
import NetworkingKitMocks
import XCTest

final class APIClientTests: XCTestCase {
    private let baseURL = URL(string: "https://example.com/api/")!

    func test_decodesASuccessfulResponse() async throws {
        let sut = makeSUT(.ok(Data(#"{"name":"Apple"}"#.utf8)))

        let item = try await sut.execute(Path("item"), as: Item.self)

        XCTAssertEqual(item, Item(name: "Apple"))
    }

    func test_sendsTheEndpointResolvedAgainstTheBaseURL() async throws {
        let transport = MockHTTPClient(always: .ok(Data(#"{"name":"Apple"}"#.utf8)))
        let sut = APIClient(baseURL: baseURL, transport: transport)

        _ = try await sut.execute(Path("cart/list"), as: Item.self)

        XCTAssertEqual(transport.sentRequests.map(\.url.absoluteString), ["https://example.com/api/cart/list"])
    }

    func test_malformedBody_throwsDecodingWithTheUnderlyingCause() async {
        let sut = makeSUT(.ok(Data(#"{"title":"Apple"}"#.utf8)))

        do {
            _ = try await sut.execute(Path("item"), as: Item.self)
            XCTFail("expected a decoding error")
        } catch NetworkError.decoding(let underlying) {
            XCTAssertTrue(underlying is DecodingError)
        } catch {
            XCTFail("expected NetworkError.decoding, got \(error)")
        }
    }

    func test_statusFailure_passesThroughIntact() async {
        let body = Data("denied".utf8)
        let sut = makeSUT(.status(403, body: body))

        do {
            _ = try await sut.execute(Path("item"), as: Item.self)
            XCTFail("expected a status error")
        } catch NetworkError.unacceptableStatus(let code, let received) {
            XCTAssertEqual(code, 403)
            XCTAssertEqual(received, body)
        } catch {
            XCTFail("expected NetworkError.unacceptableStatus, got \(error)")
        }
    }

    func test_transportFailure_passesThroughIntact() async {
        let sut = makeSUT(.offline)

        do {
            _ = try await sut.execute(Path("item"), as: Item.self)
            XCTFail("expected a transport error")
        } catch let error as NetworkError {
            XCTAssertTrue(error.isOffline)
        } catch {
            XCTFail("expected NetworkError, got \(error)")
        }
    }

    func test_usesTheInjectedDecoder() async throws {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let sut = APIClient(
            baseURL: baseURL,
            transport: MockHTTPClient(always: .ok(Data(#"{"product_name":"Apple"}"#.utf8))),
            decoder: decoder
        )

        let item = try await sut.execute(Path("item"), as: SnakeItem.self)

        XCTAssertEqual(item.productName, "Apple")
    }

    private func makeSUT(_ behaviour: MockHTTPClient.Behaviour) -> APIClient {
        APIClient(baseURL: baseURL, transport: MockHTTPClient(always: behaviour))
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
