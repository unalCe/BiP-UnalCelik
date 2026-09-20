import Foundation

public struct Product: Hashable, Sendable, Codable, Identifiable {
    /// String, not Int — the API ships `"6_id_is_a_string"` alongside `"1"`.
    public let id: String
    public let name: String
    public let price: Money
    public let imageURL: URL?
    /// Detail endpoint only; `nil` from the list.
    public let productDescription: String?

    public init(
        id: String,
        name: String,
        price: Money,
        imageURL: URL?,
        productDescription: String? = nil
    ) {
        self.id = id
        self.name = name
        self.price = price
        self.imageURL = imageURL
        self.productDescription = productDescription
    }
}
