import ProductRepositoryMocks
import UITestSupport

/// What the backend answers during a UI test. Bodies are the same captured
/// JSON the unit tests decode, so both suites describe one backend.
enum LaunchScenario {
    /// The list and the detail of product `1` load.
    case productsLoaded
    /// The list is empty.
    case emptyList
    /// The first list request finds no connection; the retry succeeds.
    case offlineThenLoaded

    var stubs: [HTTPStub] {
        switch self {
        case .productsLoaded:
            return [Self.list(.ok("ProductListResponse")), Self.detail]
        case .emptyList:
            return [Self.list(.ok("EmptyProductListResponse"))]
        case .offlineThenLoaded:
            return [Self.list(.offline, .ok("ProductListResponse")), Self.detail]
        }
    }

    // MARK: - Private

    private static func list(_ replies: HTTPStub.Reply...) -> HTTPStub {
        HTTPStub(path: "cart/list", replies: replies)
    }

    private static let detail = HTTPStub(path: "cart/1/detail", replies: [.ok("ProductDetailResponse")])
}

private extension HTTPStub.Reply {
    static func ok(_ fixture: String) -> Self {
        .response(status: 200, body: ProductFixture.data(fixture))
    }
}
