import NetworkingKit
import ProductDomain
import XCTest
@testable import ProductRepositoryLive

final class DomainErrorMapperTests: XCTestCase {
    /// The behaviour most likely to be got wrong: S3 denies listing, so an
    /// unknown product id returns 403 rather than 404.
    func test_403_mapsToNotFound() {
        XCTAssertEqual(
            DomainErrorMapper.map(NetworkError.unacceptableStatus(code: 403, body: Data())),
            .notFound
        )
    }

    func test_404_mapsToNotFound() {
        XCTAssertEqual(
            DomainErrorMapper.map(NetworkError.unacceptableStatus(code: 404, body: Data())),
            .notFound
        )
    }

    func test_500_mapsToUnknown() {
        XCTAssertEqual(
            DomainErrorMapper.map(NetworkError.unacceptableStatus(code: 500, body: Data())),
            .unknown
        )
    }

    func test_noConnection_mapsToOffline() {
        let underlying = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        XCTAssertEqual(DomainErrorMapper.map(NetworkError.transport(underlying)), .offline)
    }

    func test_domainError_passesThroughUnchanged() {
        XCTAssertEqual(DomainErrorMapper.map(DomainError.invalidData), .invalidData)
    }
}
