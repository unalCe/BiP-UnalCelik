import Foundation

public enum NetworkError: Error, Sendable {
    case invalidURL
    case transport(Error)
    case unacceptableStatus(code: Int, body: Data)
    case invalidResponse
}

public extension NetworkError {
    var isOffline: Bool {
        guard case .transport(let underlying) = self else { return false }
        let nsError = underlying as NSError
        guard nsError.domain == NSURLErrorDomain else { return false }
        return [
            NSURLErrorNotConnectedToInternet,
            NSURLErrorNetworkConnectionLost,
            NSURLErrorDataNotAllowed,
            NSURLErrorTimedOut,
        ].contains(nsError.code)
    }
}
