import ImageCacheKit
import ProductDomain
import ProductListInterface
import UIKit

@MainActor
public struct VIPERProductListModule: ProductListInterface {
    private let fetchProducts: FetchProductsUseCase
    private let imageLoader: ImageLoaderInterface
    private let prefetcher: ImagePrefetchingInterface

    public init(fetchProducts: FetchProductsUseCase,
                imageLoader: ImageLoaderInterface,
                prefetcher: ImagePrefetchingInterface) {
        self.fetchProducts = fetchProducts
        self.imageLoader = imageLoader
        self.prefetcher = prefetcher
    }

    public func createModule(navigationController: UINavigationController?) -> UIViewController {
        let view = ProductListViewController(imageLoader: imageLoader, imagePrefetcher: prefetcher)
        let interactor = ProductListInteractor(fetchProducts: fetchProducts)
        let router = ProductListRouter(navigationController: navigationController)
        let presenter = ProductListPresenter(interactor: interactor, router: router)

        presenter.view = view
        view.presenter = presenter

        return view
    }
}
