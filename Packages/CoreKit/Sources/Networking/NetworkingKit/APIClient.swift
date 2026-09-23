import Foundation

public struct APIClient: Sendable {
    private let baseURL: URL
    private let transport: HTTPClientInterface
    private let decoder: JSONDecoder

    public init(baseURL: URL, transport: HTTPClientInterface, decoder: JSONDecoder = JSONDecoder()) {
        self.baseURL = baseURL
        self.transport = transport
        self.decoder = decoder
    }

    public func execute<Response: Decodable>(
        _ endpoint: Endpoint,
        as type: Response.Type = Response.self
    ) async throws -> Response {
        let response = try await transport.send(endpoint.makeRequest(baseURL: baseURL))
        do {
            return try decoder.decode(type, from: response.body)
        } catch {
            throw NetworkError.decoding(error)
        }
    }
}
