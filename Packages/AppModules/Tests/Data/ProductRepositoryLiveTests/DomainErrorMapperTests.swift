import LoggingKitMocks
import NetworkingKit
import NetworkingKitMocks
import ProductRepositoryMocks
import PersistenceKit
import ProductDomain
import SharedDomain
import XCTest

@testable import ProductRepositoryLive

final class DomainErrorMapperTests: XCTestCase {
    private var mapper: DomainErrorMapper!
    private var logger: SpyLogger!

    override func setUp() {
        super.setUp()
        logger = SpyLogger()
        mapper = DomainErrorMapper(logger: logger)
    }

    override func tearDown() {
        mapper = nil
        logger = nil
        super.tearDown()
    }

    func test_refusalWithAMessage_surfacesTheBackendsOwnWords() {
        XCTAssertEqual(
            mapper.map(status(403, body: ProductFixture.data("AccessDenied", extension: "xml"))),
            .server(message: "Access Denied")
        )
        XCTAssertEqual(logger.errors.count, 1)
    }

    /// No status code is given a meaning of ours: without a message, a 404 is
    /// as generic as a 500.
    func test_statusWithoutAMessage_mapsToUnknown() {
        XCTAssertEqual(mapper.map(status(404)), .unknown)
        XCTAssertEqual(mapper.map(status(500)), .unknown)
    }

    func test_unreadableBody_mapsToUnknown() {
        XCTAssertEqual(mapper.map(status(502, body: Data("<html>Bad Gateway</html>".utf8))), .unknown)
    }

    func test_noConnection_mapsToOffline() {
        let underlying = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        XCTAssertEqual(mapper.map(NetworkError.transport(underlying)), .offline)
    }

    func test_decodingFailure_mapsToInvalidData_andIsLogged() {
        struct Mismatch: Error {}

        XCTAssertEqual(mapper.map(NetworkError.decoding(Mismatch())), .invalidData)
        XCTAssertEqual(logger.errors.map(\.category), [.networking])
    }

    func test_domainError_passesThroughUnchanged() {
        XCTAssertEqual(mapper.map(DomainError.invalidData), .invalidData)
    }

    /// `DomainError` cannot carry the cause, so the log has to.
    func test_persistenceError_isLoggedBeforeBecomingUnknown() {
        struct Disk: Error {}

        XCTAssertEqual(mapper.map(PersistenceError.readFailed(Disk())), .unknown)
        XCTAssertEqual(logger.errors.map(\.category), [.persistence])
    }

    private func status(_ code: Int, body: Data = Data()) -> NetworkError {
        .unacceptableStatus(code: code, body: body)
    }
}
