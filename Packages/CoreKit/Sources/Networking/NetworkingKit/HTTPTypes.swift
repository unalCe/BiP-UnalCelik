import Foundation

public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

/// Kept free of `URLRequest.CachePolicy` so the interface stays transport-agnostic.
public enum HTTPCachePolicy: Sendable, Equatable {
    /// Whatever the response headers say. Right for immutable bytes such as images.
    case standard
    /// Always ask, and accept a 304. Right for anything that can change, and
    /// necessary here: these endpoints send no `Cache-Control`, so heuristic
    /// freshness against a 2015 `Last-Modified` would pin the response for
    /// roughly a year.
    case revalidate
}

public struct HTTPRequest: Sendable, Equatable {
    public var url: URL
    public var method: HTTPMethod
    public var headers: [String: String]
    public var body: Data?
    public var cachePolicy: HTTPCachePolicy

    public init(
        url: URL,
        method: HTTPMethod = .get,
        headers: [String: String] = [:],
        body: Data? = nil,
        cachePolicy: HTTPCachePolicy = .standard
    ) {
        self.url = url
        self.method = method
        self.headers = headers
        self.body = body
        self.cachePolicy = cachePolicy
    }
}

public struct HTTPResponse: Sendable, Equatable {
    public let statusCode: Int
    public let headers: [String: String]
    public let body: Data

    public init(statusCode: Int, headers: [String: String] = [:], body: Data) {
        self.statusCode = statusCode
        self.headers = headers
        self.body = body
    }

    public var isSuccess: Bool { (200..<300).contains(statusCode) }
}
