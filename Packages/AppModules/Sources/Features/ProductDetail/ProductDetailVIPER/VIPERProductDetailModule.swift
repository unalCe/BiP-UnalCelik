import ProductDetailInterface
import ProductDomain
import UIKit

@MainActor
public struct VIPERProductDetailModule: ProductDetailInterface {
    private let fetchDetail: any FetchProductDetailUseCase

    public init(fetchDetail: any FetchProductDetailUseCase) {
        self.fetchDetail = fetchDetail
    }

    public func createModule(
        navigationController: UINavigationController?,
        productID: String
    ) -> UIViewController {
        let view = ProductDetailViewController()
        let interactor = ProductDetailInteractor(fetchDetail: fetchDetail)
        let router = ProductDetailRouter(navigationController: navigationController)
        let presenter = ProductDetailPresenter(
            productID: productID,
            interactor: interactor,
            router: router
        )

        presenter.view = view
        view.presenter = presenter

        return view
    }
}
