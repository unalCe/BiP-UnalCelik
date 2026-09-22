import Foundation
import LoggingKit
import NetworkingKit
import ProductDomain

protocol ProductRemoteDataSource: Sendable {
    func products() async throws -> [Product]
    func product(id: String) async throws -> Product
}

struct HTTPProductRemoteDataSource: ProductRemoteDataSource {
    private let client: any HTTPClientInterface
    private let baseURL: URL
    private let logger: any LoggerInterface
    private let errorMapper: DomainErrorMapper
    private let decoder = JSONDecoder()

    init(client: any HTTPClientInterface, baseURL: URL, logger: any LoggerInterface) {
        self.client = client
        self.baseURL = baseURL
        self.logger = logger
        errorMapper = DomainErrorMapper(logger: logger)
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
            throw errorMapper.map(error, for: endpoint)
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try decoder.decode(type, from: data)
        } catch {
            // the user sees .invalidData; which key or type broke is only here
            logger.error("decoding \(T.self) failed: \(error)", category: .networking)
            throw DomainError.invalidData
        }
    }
}
