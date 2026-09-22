import Foundation
import LoggingKit
import NetworkingKit
import PersistenceKit
import ProductDomain

/// `DomainError` stays free of infrastructure types, so whatever it cannot
/// carry is logged here, at the one place it is thrown away.
struct DomainErrorMapper {
    private let logger: any LoggerInterface

    init(logger: any LoggerInterface) {
        self.logger = logger
    }

    func map(_ error: any Error, for endpoint: ProductEndpoint) -> DomainError {
        switch error {
        case let error as DomainError:
            return error
        case let error as NetworkError:
            return map(error, for: endpoint)
        case is PersistenceError:
            logger.error("\(endpoint) persistence failure surfaced as .unknown: \(error)", category: .persistence)
            return .unknown
        default:
            logger.error("\(endpoint) unexpected failure surfaced as .unknown: \(error)", category: .networking)
            return .unknown
        }
    }

    private func map(_ error: NetworkError, for endpoint: ProductEndpoint) -> DomainError {
        switch error {
        // 403 is not a typo — the bucket denies listing, so unknown ids come
        // back AccessDenied. Only a request that names a product can be told
        // "not found"; on the list the same code is an access failure.
        case .unacceptableStatus(let code, _) where code == 403 || code == 404:
            if endpoint.namesOneProduct { return .notFound }
            logger.error("\(endpoint) was refused with \(code)", category: .networking)
            return .unknown
        case .unacceptableStatus(let code, _):
            logger.error("\(endpoint) failed with \(code)", category: .networking)
            return .unknown
        case .transport where error.isOffline:
            return .offline
        case .transport, .invalidResponse, .invalidURL:
            logger.error("\(endpoint) failed: \(error)", category: .networking)
            return .unknown
        }
    }
}
