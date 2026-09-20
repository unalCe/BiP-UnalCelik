import Foundation

public enum DomainError: Error, Equatable, Sendable {
    /// Also covers 403 — the bucket denies listing, so unknown ids come back
    /// AccessDenied rather than 404.
    case notFound
    case offline
    case invalidData
    case unknown
}
