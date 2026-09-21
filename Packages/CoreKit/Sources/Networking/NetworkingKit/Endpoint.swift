import Foundation

public protocol Endpoint: Sendable {
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String] { get }
    var body: Data? { get }
    var cachePolicy: HTTPCachePolicy { get }
}

public extension Endpoint {
    var method: HTTPMethod { .get }
    var headers: [String: String] { [:] }
    var body: Data? { nil }
    var cachePolicy: HTTPCachePolicy { .standard }

    func makeRequest(baseURL: URL) throws -> HTTPRequest {
        guard let url = URL(string: path, relativeTo: baseURL) else {
            throw NetworkError.invalidURL
        }
        return HTTPRequest(
            url: url, method: method, headers: headers, body: body, cachePolicy: cachePolicy
        )
    }
}
