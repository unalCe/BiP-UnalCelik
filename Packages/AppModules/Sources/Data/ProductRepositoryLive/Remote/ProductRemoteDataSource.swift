import Foundation
import NetworkingKit
import ProductDomain

protocol ProductRemoteDataSource: Sendable {
    func products() async throws -> [Product]
    func product(id: String) async throws -> Product
}

struct HTTPProductRemoteDataSource: ProductRemoteDataSource {
    private let apiClient: APIClient

    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }

    func products() async throws -> [Product] {
        let response = try await apiClient.execute(ProductEndpoint.list, as: ProductListResponseDTO.self)
        return ProductMapper.map(response.products)
    }

    func product(id: String) async throws -> Product {
        let response = try await apiClient.execute(ProductEndpoint.detail(id: id), as: ProductDTO.self)
        return ProductMapper.map(response)
    }
}
