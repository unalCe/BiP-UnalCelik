import Foundation
import NetworkingKit

// TODO: maybe think about retry mechanisms, interceptors
public struct URLSessionHTTPClient: HTTPClientInterface {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func send(_ request: HTTPRequest) async throws -> HTTPResponse {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = request.body
        urlRequest.cachePolicy = request.cachePolicy.urlRequestPolicy
        request.headers.forEach { urlRequest.setValue($1, forHTTPHeaderField: $0) }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: urlRequest)
        } catch {
            throw NetworkError.transport(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        let headers = http.allHeaderFields.reduce(into: [String: String]()) { acc, pair in
            if let key = pair.key as? String, let value = pair.value as? String {
                acc[key] = value
            }
        }

        let result = HTTPResponse(statusCode: http.statusCode, headers: headers, body: data)
        guard result.isSuccess else {
            throw NetworkError.unacceptableStatus(code: http.statusCode, body: data)
        }
        return result
    }
}

private extension HTTPCachePolicy {
    var urlRequestPolicy: URLRequest.CachePolicy {
        switch self {
        case .standard: .useProtocolCachePolicy
        case .revalidate: .reloadRevalidatingCacheData
        }
    }
}
