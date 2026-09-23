import Foundation

public struct ProductDisplayModel: Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let formattedPrice: String
    public let description: String?
    public let imageURL: URL?
}
