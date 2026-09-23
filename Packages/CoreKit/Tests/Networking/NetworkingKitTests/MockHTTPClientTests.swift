import XCTest
import NetworkingKit
import NetworkingKitMocks

/// Exercises the mock itself — downstream modules rely on its behaviour, so it
/// deserves the same scrutiny as production code.
final class MockHTTPClientTests: XCTestCase {
    private let url = URL(string: "https://example.com/cart/list")!

    func test_always_repeatsTheSameBehaviour() async throws {
        let sut = MockHTTPClient(always: .ok(HTTPFixtures.productList))

        _ = try await sut.send(HTTPRequest(url: url))
        let second = try await sut.send(HTTPRequest(url: url))

        XCTAssertEqual(second.statusCode, 200)
        XCTAssertEqual(sut.sendCount, 2)
    }

    func test_queue_answersInOrder() async throws {
        let sut = MockHTTPClient(queue: [.status(403), .ok(HTTPFixtures.productDetail)])

        await XCTAssertThrowsErrorAsync(try await sut.send(HTTPRequest(url: url)))
        let second = try await sut.send(HTTPRequest(url: url))

        XCTAssertEqual(second.body, HTTPFixtures.productDetail)
    }

    func test_recordsRequests() async throws {
        let sut = MockHTTPClient(always: .ok(Data()))
        _ = try await sut.send(HTTPRequest(url: url, method: .get))

        XCTAssertEqual(sut.sentRequests.map(\.url), [url])
    }

    func test_offlineBehaviour_isRecognisedByNetworkError() async {
        let sut = MockHTTPClient(always: .offline)

        do {
            _ = try await sut.send(HTTPRequest(url: url))
            XCTFail("expected a failure")
        } catch let error as NetworkError {
            XCTAssertTrue(error.isOffline)
        } catch {
            XCTFail("expected NetworkError, got \(error)")
        }
    }
}

func XCTAssertThrowsErrorAsync(
    _ expression: @autoclosure () async throws -> some Any,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        _ = try await expression()
        XCTFail("expected an error", file: file, line: line)
    } catch {
        // expected
    }
}
