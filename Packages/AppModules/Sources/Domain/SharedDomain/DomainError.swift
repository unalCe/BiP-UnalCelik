import Foundation

public enum DomainError: Error, Equatable, Sendable {
    /// The backend refused the request and said why; `message` is its own text.
    case server(message: String)
    case offline
    case invalidData
    case unknown
}
