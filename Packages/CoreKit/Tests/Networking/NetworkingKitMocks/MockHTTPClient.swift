import Foundation
import NetworkingKit

/// Records requests, returns what you queued.
public final class MockHTTPClient: HTTPClientInterface, @unchecked Sendable {
    public enum Behaviour: Sendable {
        case success(HTTPResponse)
        case failure(NetworkError)
    }

    private let lock = NSLock()
    private var queued: [Behaviour]
    private var defaultBehaviour: Behaviour?
    private var recorded: [HTTPRequest] = []

    // MARK: - Lifecycle

    public init(always behaviour: Behaviour) {
        self.queued = []
        self.defaultBehaviour = behaviour
    }

    /// Answers in order; running past the end traps.
    public init(queue: [Behaviour]) {
        self.queued = queue
        self.defaultBehaviour = nil
    }

    // MARK: - Public Funcs

    public var sentRequests: [HTTPRequest] {
        lock.withLock { recorded }
    }

    public var sendCount: Int { sentRequests.count }

    public func send(_ request: HTTPRequest) async throws -> HTTPResponse {
        let behaviour: Behaviour = lock.withLock {
            recorded.append(request)
            if !queued.isEmpty { return queued.removeFirst() }
            guard let defaultBehaviour else {
                fatalError("MockHTTPClient ran out of queued behaviours")
            }
            return defaultBehaviour
        }

        switch behaviour {
        case .success(let response): return response
        case .failure(let error): throw error
        }
    }
}

public extension MockHTTPClient.Behaviour {
    static func ok(_ body: Data) -> Self {
        .success(HTTPResponse(statusCode: 200, body: body))
    }

    static func status(_ code: Int, body: Data = Data()) -> Self {
        .failure(.unacceptableStatus(code: code, body: body))
    }

    static var offline: Self {
        .failure(.transport(NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorNotConnectedToInternet
        )))
    }
}
