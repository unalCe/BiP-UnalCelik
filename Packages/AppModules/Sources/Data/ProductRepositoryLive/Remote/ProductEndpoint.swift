import Foundation
import NetworkingKit

enum ProductEndpoint: Endpoint {
    case list
    case detail(id: String)

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
