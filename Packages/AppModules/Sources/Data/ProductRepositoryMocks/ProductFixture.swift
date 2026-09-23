import Foundation
import ProductAPI
import ProductDomain

/// Captured API responses, decoded through the same DTOs and mapper the live
/// repository uses. A presenter or view model test therefore sees exactly what
/// the app would show for that payload — and if the wire format or the mapping
/// changes, the fixtures change with it instead of silently drifting.
public enum ProductFixture {
    /// `GET /cart/list`.
    public static func list(_ name: String = "ProductListResponse") -> [Product] {
        ProductMapper.map(decode(ProductListResponseDTO.self, from: name).products)
    }

    /// `GET /cart/{id}/detail`.
    public static func detail(_ name: String = "ProductDetailResponse") -> Product {
        ProductMapper.map(decode(ProductDTO.self, from: name))
    }

    /// The raw bytes, for tests that feed a mock HTTP client.
    public static func data(_ name: String, extension fileExtension: String = "json") -> Data {
        guard let url = Bundle.module.url(forResource: name, withExtension: fileExtension) else {
            preconditionFailure("no fixture \(name).\(fileExtension) in ProductRepositoryMocks/Resources")
        }
        do {
            return try Data(contentsOf: url)
        } catch {
            preconditionFailure("unreadable fixture \(name).\(fileExtension): \(error)")
        }
    }

    // MARK: - Private Funcs

    private static func decode<T: Decodable>(_ type: T.Type, from name: String) -> T {
        do {
            return try JSONDecoder().decode(type, from: data(name))
        } catch {
            preconditionFailure("\(name).json does not decode as \(T.self): \(error)")
        }
    }
}
