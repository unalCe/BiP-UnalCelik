import Foundation
import NetworkingKit
import PersistenceKit
import ProductDomain

enum DomainErrorMapper {
    static func map(_ error: any Error) -> DomainError {
        switch error {
        case let error as DomainError:
            return error
        case let error as NetworkError:
            return map(error)
        case is PersistenceError:
            return .unknown
        default:
            return .unknown
        }
    }

    static func map(_ error: NetworkError) -> DomainError {
        switch error {
        // 403 is not a typo — the bucket denies listing, so unknown ids come
        // back AccessDenied. Mapping it to .unknown would show the user
        // "something went wrong" instead of "product not found".
        case .unacceptableStatus(let code, _) where code == 403 || code == 404:
            return .notFound
        case .unacceptableStatus:
            return .unknown
        case .transport:
            return error.isOffline ? .offline : .unknown
        case .invalidResponse, .invalidURL:
            return .unknown
        }
    }
}
