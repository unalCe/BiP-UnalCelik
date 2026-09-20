import ImageCacheKit
import ProductDomain
import ProductListInterface
import ProductListMVVM
import UIKit

@MainActor
public struct MVVMUIKitProductListModule: ProductListInterface {
    private let fetchProducts: any FetchProductsUseCase
    private let imageLoader: any ImageLoaderInterface
    private let prefetcher: any ImagePrefetchingInterface
    private let onSelectProduct: (String, UINavigationController?) -> Void

    public init(
        fetchProducts: any FetchProductsUseCase,
        imageLoader: any ImageLoaderInterface,
        prefetcher: any ImagePrefetchingInterface,
        onSelectProduct: @escaping (String, UINavigationController?) -> Void
    ) {
        self.fetchProducts = fetchProducts
        self.imageLoader = imageLoader
        self.prefetcher = prefetcher
        self.onSelectProduct = onSelectProduct
    }

    public func createModule(navigationController: UINavigationController?) -> UIViewController {
        let viewModel = ProductListViewModel(
            fetchProducts: fetchProducts,
            prefetcher: prefetcher
        )
        viewModel.onSelectProduct = { [onSelectProduct] id in
            onSelectProduct(id, navigationController)
        }
        return ProductListViewController(viewModel: viewModel, imageLoader: imageLoader)
    }
}
