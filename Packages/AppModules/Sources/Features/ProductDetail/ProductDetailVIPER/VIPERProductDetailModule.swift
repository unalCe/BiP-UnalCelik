import ImageCacheKit
import ProductDetailInterface
import ProductDomain
import UIKit

@MainActor
public struct VIPERProductDetailModule: ProductDetailInterface {
    private let fetchDetail: any FetchProductDetailUseCase
    private let imageLoader: any ImageLoaderInterface

    public init(fetchDetail: any FetchProductDetailUseCase,
                imageLoader: any ImageLoaderInterface) {
        self.fetchDetail = fetchDetail
        self.imageLoader = imageLoader
    }

    public func createModule(
        navigationController: UINavigationController?,
        productID: String
    ) -> UIViewController {
        let view = ProductDetailViewController(imageLoader: imageLoader)
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
