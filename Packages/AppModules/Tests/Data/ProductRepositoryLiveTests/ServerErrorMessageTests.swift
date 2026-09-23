import ProductRepositoryMocks
import XCTest

@testable import ProductRepositoryLive

final class ServerErrorMessageTests: XCTestCase {
    func test_s3Refusal_yieldsItsMessage() {
        let body = ProductFixture.data("AccessDenied", extension: "xml")

        XCTAssertEqual(ServerErrorMessage.extract(from: body), "Access Denied")
    }

    func test_surroundingWhitespace_isTrimmed() {
        let body = Data("<Error><Message>\n  Slow down  \n</Message></Error>".utf8)

        XCTAssertEqual(ServerErrorMessage.extract(from: body), "Slow down")
    }

    func test_emptyBody_hasNoMessage() {
        XCTAssertNil(ServerErrorMessage.extract(from: Data()))
    }

    func test_bodyWithoutAMessageElement_hasNoMessage() {
        let body = Data("<Error><Code>AccessDenied</Code></Error>".utf8)

        XCTAssertNil(ServerErrorMessage.extract(from: body))
    }

    func test_nonXMLBody_hasNoMessage() {
        XCTAssertNil(ServerErrorMessage.extract(from: Data("<html>Bad Gateway".utf8)))
    }
}
