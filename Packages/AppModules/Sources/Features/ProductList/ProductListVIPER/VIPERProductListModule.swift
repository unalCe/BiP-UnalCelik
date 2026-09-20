import ProductDomain
import ProductListInterface
import UIKit

@MainActor
public struct VIPERProductListModule: ProductListInterface {
    private let fetchProducts: any FetchProductsUseCase

    public init(fetchProducts: any FetchProductsUseCase) {
        self.fetchProducts = fetchProducts
    }

    public func createModule(navigationController: UINavigationController?) -> UIViewController {
        let view = ProductListViewController()
        let interactor = ProductListInteractor(fetchProducts: fetchProducts)
        let router = ProductListRouter(navigationController: navigationController)
        let presenter = ProductListPresenter(interactor: interactor, router: router)

        presenter.view = view
        view.presenter = presenter

        return view
    }
}
