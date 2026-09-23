import ImageCacheKit
import ProductDomain
import ProductListInterface
import ProductListMVVM
import UIKit

@MainActor
public struct MVVMUIKitProductListModule: ProductListScreenFactory {
    private let fetchProducts: FetchProductsUseCase
    private let imageLoader: ImageLoaderInterface
    private let prefetcher: ImagePrefetchingInterface

    public init(
        fetchProducts: FetchProductsUseCase,
        imageLoader: ImageLoaderInterface,
        prefetcher: ImagePrefetchingInterface
    ) {
        self.fetchProducts = fetchProducts
        self.imageLoader = imageLoader
        self.prefetcher = prefetcher
    }

    public func makeScreen(onSelectProduct: @escaping (String) -> Void) -> UIViewController {
        let viewModel = ProductListViewModel(fetchProducts: fetchProducts)
        viewModel.onSelectProduct = onSelectProduct
        return ProductListViewController(
            viewModel: viewModel,
            imageLoader: imageLoader,
            imagePrefetcher: prefetcher
        )
    }
}
