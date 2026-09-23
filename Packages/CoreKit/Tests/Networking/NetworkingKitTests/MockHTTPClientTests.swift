import NetworkingKit
import NetworkingKitMocks
import TestSupport
import XCTest

/// Exercises the mock itself — downstream modules rely on its behaviour, so it
/// deserves the same scrutiny as production code.
final class MockHTTPClientTests: XCTestCase {
    private let request = HTTPRequest(url: URL(string: "https://example.com/cart/list")!)
    private let body = Data(#"{"name":"Apple"}"#.utf8)

    func test_always_repeatsTheSameBehaviour() async throws {
        let client = MockHTTPClient(always: .ok(body))

        _ = try await client.send(request)
        let second = try await client.send(request)

        XCTAssertEqual(second, HTTPResponse(statusCode: 200, body: body))
        XCTAssertEqual(client.sendCount, 2)
    }

    func test_queue_answersInOrder() async throws {
        let client = MockHTTPClient(queue: [.status(403), .ok(body)])

        await XCTAssertThrowsErrorAsync(try await client.send(request))
        let second = try await client.send(request)

        XCTAssertEqual(second.body, body)
    }

    func test_recordsRequests() async throws {
        let client = MockHTTPClient(always: .ok(Data()))

        _ = try await client.send(request)

        XCTAssertEqual(client.sentRequests, [request])
    }

    func test_offlineBehaviour_isRecognisedByNetworkError() async {
        let client = MockHTTPClient(always: .offline)

        await XCTAssertThrowsErrorAsync(try await client.send(request)) { error in
            XCTAssertEqual((error as? NetworkError)?.isOffline, true, "got \(error)")
        }
    }
}
