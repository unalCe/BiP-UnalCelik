import Foundation

struct ProductListResponseDTO: Decodable {
    let products: [ProductDTO]
}

struct ProductDTO: Decodable {
    let productId: String
    let name: String
    let price: Int
    let image: String?
    let description: String?

    enum CodingKeys: String, CodingKey {
        case productId = "product_id"
        case name, price, image, description
    }
}
