import CommonKit
import Foundation
import ProductPresentation

@MainActor
public protocol ProductListViewInterface: AnyObject {
    var presenter: ProductListPresenterInterface? { get set }
    func display(_ state: ViewState<[ProductDisplayModel]>)
}

@MainActor
public protocol ProductListPresenterInterface: AnyObject {
    func viewDidLoad()
    func didSelectItem(at index: Int)
    func didTapRetry()
}

public protocol ProductListInteractorInterface: Sendable {
    func loadProducts() async throws -> [ProductDisplayModel]
}

@MainActor
public protocol ProductListRouterInterface: AnyObject {
    func routeToDetail(productID: String)
}
