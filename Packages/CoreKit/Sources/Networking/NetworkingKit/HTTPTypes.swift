import Foundation

public enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

public enum HTTPCachePolicy: Sendable, Equatable {
    case standard    // whatever the response headers say
    case revalidate  // always ask; accept a 304
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
