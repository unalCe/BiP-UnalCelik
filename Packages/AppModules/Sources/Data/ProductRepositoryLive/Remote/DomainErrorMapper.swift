import Foundation
import LoggingKit
import NetworkingKit
import PersistenceKit
import ProductDomain

/// `DomainError` stays free of infrastructure types, so whatever it cannot
/// carry is logged here, at the one place it is thrown away.
struct DomainErrorMapper {
    private let logger: LoggerInterface

    init(logger: LoggerInterface) {
        self.logger = logger
    }

    func map(_ error: Error) -> DomainError {
        switch error {
        case let error as DomainError:
            return error
        case let error as NetworkError:
            return map(error)
        case is PersistenceError:
            logger.error("persistence failure surfaced as .unknown: \(error)", category: .persistence)
            return .unknown
        default:
            logger.error("unexpected failure surfaced as .unknown: \(error)", category: .networking)
            return .unknown
        }
    }

    // the backend's own words are shown as they are; no status code is given
    // a meaning of ours
    private func map(_ error: NetworkError) -> DomainError {
        switch error {
        case .unacceptableStatus(let code, let body):
            logger.error("request failed with \(code)", category: .networking)
            guard let message = ServerErrorMessage.extract(from: body) else { return .unknown }
            return .server(message: message)
        case .transport where error.isOffline:
            return .offline
        case .transport, .invalidResponse, .invalidURL:
            logger.error("request failed: \(error)", category: .networking)
            return .unknown
        }
    }
}
