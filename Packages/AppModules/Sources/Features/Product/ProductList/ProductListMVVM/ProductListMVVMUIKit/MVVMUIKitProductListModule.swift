import ImageCacheKit
import ProductDomain
import ProductListInterface
import ProductListMVVM
import UIKit

@MainActor
public struct MVVMUIKitProductListModule: ProductListInterface {
    private let fetchProducts: FetchProductsUseCase
    private let imageLoader: ImageLoaderInterface
    private let prefetcher: ImagePrefetchingInterface
    private let onSelectProduct: (String, UINavigationController?) -> Void

    public init(
        fetchProducts: FetchProductsUseCase,
        imageLoader: ImageLoaderInterface,
        prefetcher: ImagePrefetchingInterface,
        onSelectProduct: @escaping (String, UINavigationController?) -> Void
    ) {
        self.fetchProducts = fetchProducts
        self.imageLoader = imageLoader
        self.prefetcher = prefetcher
        self.onSelectProduct = onSelectProduct
    }

    public func createModule(navigationController: UINavigationController?) -> UIViewController {
        let viewModel = ProductListViewModel(fetchProducts: fetchProducts)
        viewModel.onSelectProduct = { [onSelectProduct] id in
            onSelectProduct(id, navigationController)
        }
        return ProductListViewController(
            viewModel: viewModel,
            imageLoader: imageLoader,
            imagePrefetcher: prefetcher
        )
    }
}
