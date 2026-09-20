import Foundation
import NetworkingKit
import ProductDomain

protocol ProductRemoteDataSource: Sendable {
    func products() async throws -> [Product]
    func product(id: String) async throws -> Product
}

struct HTTPProductRemoteDataSource: ProductRemoteDataSource {
    private let client: any HTTPClientInterface
    private let baseURL: URL
    private let decoder = JSONDecoder()

    init(client: any HTTPClientInterface, baseURL: URL) {
        self.client = client
        self.baseURL = baseURL
    }

    func products() async throws -> [Product] {
        let response = try await send(.list)
        return ProductMapper.map(try decode(ProductListResponseDTO.self, from: response.body).products)
    }

    func product(id: String) async throws -> Product {
        let response = try await send(.detail(id: id))
        return ProductMapper.map(try decode(ProductDTO.self, from: response.body))
    }

    private func send(_ endpoint: ProductEndpoint) async throws -> HTTPResponse {
        do {
            return try await client.send(endpoint.makeRequest(baseURL: baseURL))
        } catch {
            throw DomainErrorMapper.map(error)
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw DomainError.invalidData
        }
    }
}
