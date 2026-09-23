import Foundation

/// The wire format of the product endpoints, exactly as the backend sends it.
/// Public so the fixtures in `ProductRepositoryMocks` decode through the same
/// types the live repository does.
public struct ProductListResponseDTO: Decodable {
    public let products: [ProductDTO]
}

public struct ProductDTO: Decodable {
    public let productId: String
    public let name: String
    public let price: Int
    public let image: String?
    public let description: String?

    enum CodingKeys: String, CodingKey {
        case productId = "product_id"
        case name, price, image, description
    }
}
