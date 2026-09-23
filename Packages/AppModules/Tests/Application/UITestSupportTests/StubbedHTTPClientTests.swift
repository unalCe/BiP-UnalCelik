import NetworkingKit
import TestSupport
import UIKit
import XCTest

@testable import UITestSupport

final class StubbedHTTPClientTests: XCTestCase {
    private var client: StubbedHTTPClient!

    private let listBody = Data(#"{ "products": [] }"#.utf8)
    private let baseURL = URL(string: "https://example.com/developer-application-test/")!

    override func setUp() {
        super.setUp()
        reCreate()
    }

    override func tearDown() {
        client = nil
        super.tearDown()
    }

    private func reCreate(stubs: [HTTPStub]? = nil) {
        client = StubbedHTTPClient(stubs: stubs ?? [
            HTTPStub(path: "cart/list", replies: [.response(status: 200, body: listBody)]),
        ])
    }

    private func request(_ path: String) -> HTTPRequest {
        HTTPRequest(url: baseURL.appendingPathComponent(path))
    }

    func test_matchingPath_answersWithTheStubbedBody() async throws {
        let response = try await client.send(request("cart/list"))

        XCTAssertEqual(response.statusCode, 200)
        XCTAssertEqual(response.body, listBody)
    }

    func test_replies_areAnsweredInOrder_andTheLastRepeats() async throws {
        reCreate(stubs: [HTTPStub(path: "cart/list", replies: [.offline, .response(status: 200, body: listBody)])])

        await XCTAssertThrowsErrorAsync(try await client.send(request("cart/list")))
        let second = try await client.send(request("cart/list"))
        let third = try await client.send(request("cart/list"))

        XCTAssertEqual(second.body, listBody)
        XCTAssertEqual(third.body, listBody)
    }

    func test_offline_isAnOfflineTransportError() async {
        reCreate(stubs: [HTTPStub(path: "cart/list", replies: [.offline])])

        await XCTAssertThrowsErrorAsync(try await client.send(request("cart/list"))) { error in
            XCTAssertEqual((error as? NetworkError)?.isOffline, true, "got \(error)")
        }
    }

    func test_errorStatus_throwsWithTheBody() async {
        let body = Data("<Error><Message>Access Denied</Message></Error>".utf8)
        reCreate(stubs: [HTTPStub(path: "cart/list", replies: [.response(status: 403, body: body)])])

        await XCTAssertThrowsErrorAsync(try await client.send(request("cart/list"))) { error in
            guard case NetworkError.unacceptableStatus(let code, let received) = error else {
                return XCTFail("expected unacceptableStatus, got \(error)")
            }
            XCTAssertEqual(code, 403)
            XCTAssertEqual(received, body)
        }
    }

    func test_unstubbedImage_getsADecodableImage() async throws {
        let response = try await client.send(request("images/1.jpg"))

        XCTAssertNotNil(UIImage(data: response.body))
    }

    func test_unstubbedRequest_isA404() async {
        await XCTAssertThrowsErrorAsync(try await client.send(request("cart/99/detail"))) { error in
            guard case NetworkError.unacceptableStatus(404, _) = error else {
                return XCTFail("expected a 404, got \(error)")
            }
        }
    }
}
