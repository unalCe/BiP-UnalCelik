import Foundation
import ProductDomain

enum ProductMapper {
    static func map(_ dto: ProductDTO) -> Product {
        Product(
            id: dto.productId,
            name: dto.name,
            price: Money(minorUnits: dto.price),
            imageURL: dto.image.flatMap(URL.init(string:)),
            productDescription: dto.description
        )
    }

    static func map(_ dtos: [ProductDTO]) -> [Product] { dtos.map(map) }
}
