import Foundation
import NetworkingKit

enum ProductEndpoint: Endpoint {
    case list
    case detail(id: String)

    var cachePolicy: HTTPCachePolicy { .revalidate }

    var path: String {
        switch self {
        case .list:
            return "cart/list"
        case .detail(let id):
            // ids aren't guaranteed numeric, so encode before interpolating
            let encoded = id.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? id
            return "cart/\(encoded)/detail"
        }
    }
}

extension ProductEndpoint {
    /// Whether a 403/404 here can only mean "no such product". True for detail,
    /// which names one; the list names none, so the same code there is an
    /// access failure.
    var namesOneProduct: Bool {
        switch self {
        case .list: return false
        case .detail: return true
        }
    }
}
