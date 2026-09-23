import NetworkingKit
import TestSupport
import XCTest

@testable import NetworkingKitLive

/// The real client over a real `URLSession`, with the wire replaced by a
/// `URLProtocol`. Covers the translation both ways: `HTTPRequest` into
/// `URLRequest`, and `URLResponse` / `URLError` into `HTTPResponse` /
/// `NetworkError`.
final class URLSessionHTTPClientTests: XCTestCase {
    private var client: URLSessionHTTPClient!

    private let url = URL(string: "https://example.com/cart/list")!

    override func setUp() {
        super.setUp()
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        client = URLSessionHTTPClient(session: URLSession(configuration: configuration))
    }

    override func tearDown() {
        client = nil
        StubURLProtocol.reset()
        super.tearDown()
    }

    func test_success_returnsStatusHeadersAndBody() async throws {
        StubURLProtocol.respond(status: 200, headers: ["Content-Type": "application/json"], body: Data("{}".utf8))

        let response = try await client.send(HTTPRequest(url: url))

        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(response.headers["Content-Type"], "application/json")
        XCTAssertEqual(response.body, Data("{}".utf8))
    }

    func test_translatesTheRequest() async throws {
        StubURLProtocol.respond(status: 200)

        _ = try await client.send(HTTPRequest(
            url: url,
            method: .post,
            headers: ["X-Trace": "abc"],
            cachePolicy: .revalidate
        ))

        let sent = try XCTUnwrap(StubURLProtocol.receivedRequests.first)
        XCTAssertEqual(sent.url, url)
        XCTAssertEqual(sent.httpMethod, "POST")
        XCTAssertEqual(sent.value(forHTTPHeaderField: "X-Trace"), "abc")
        XCTAssertEqual(sent.cachePolicy, .reloadRevalidatingCacheData)
    }

    func test_nonSuccessStatus_throwsWithTheBody() async {
        let body = Data("<Error><Message>Access Denied</Message></Error>".utf8)
        StubURLProtocol.respond(status: 403, body: body)

        await XCTAssertThrowsErrorAsync(try await client.send(HTTPRequest(url: url))) { error in
            guard case NetworkError.unacceptableStatus(let code, let received) = error else {
                return XCTFail("expected unacceptableStatus, got \(error)")
            }
            XCTAssertEqual(code, 403)
            XCTAssertEqual(received, body)
        }
    }

    func test_noConnection_isAnOfflineTransportError() async {
        StubURLProtocol.fail(with: URLError(.notConnectedToInternet))

        await XCTAssertThrowsErrorAsync(try await client.send(HTTPRequest(url: url))) { error in
            XCTAssertEqual((error as? NetworkError)?.isOffline, true, "got \(error)")
        }
    }
}

/// Answers every request from a canned response and records what it saw.
private final class StubURLProtocol: URLProtocol {
    private enum Reply {
        case response(status: Int, headers: [String: String], body: Data)
        case failure(Error)
    }

    private static let lock = NSLock()
    nonisolated(unsafe) private static var reply: Reply?
    nonisolated(unsafe) private static var requests: [URLRequest] = []

    static var receivedRequests: [URLRequest] { lock.withLock { requests } }

    static func respond(status: Int, headers: [String: String] = [:], body: Data = Data()) {
        lock.withLock { reply = .response(status: status, headers: headers, body: body) }
    }

    static func fail(with error: Error) {
        lock.withLock { reply = .failure(error) }
    }

    static func reset() {
        lock.withLock {
            reply = nil
            requests = []
        }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let reply: Reply? = Self.lock.withLock {
            Self.requests.append(request)
            return Self.reply
        }

        switch reply {
        case .response(let status, let headers, let body):
            let response = HTTPURLResponse(
                url: request.url!, statusCode: status, httpVersion: "HTTP/1.1", headerFields: headers
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: body)
            client?.urlProtocolDidFinishLoading(self)
        case .failure(let error):
            client?.urlProtocol(self, didFailWithError: error)
        case nil:
            client?.urlProtocol(self, didFailWithError: URLError(.resourceUnavailable))
        }
    }

    override func stopLoading() {}
}
