import CommonKit
import Foundation
import ProductPresentation

@MainActor
public protocol ProductDetailViewInterface: AnyObject {
    var presenter: ProductDetailPresenterInterface? { get set }
    func display(_ state: ViewState<ProductDisplayModel>)
}

@MainActor
public protocol ProductDetailPresenterInterface: AnyObject {
    func viewDidLoad()
    func didTapRetry()
    func didTapClose()
}

public protocol ProductDetailInteractorInterface: Sendable {
    func loadProduct(id: String) async throws -> ProductDisplayModel
}

@MainActor
public protocol ProductDetailRouterInterface: AnyObject {
    func dismiss()
}
