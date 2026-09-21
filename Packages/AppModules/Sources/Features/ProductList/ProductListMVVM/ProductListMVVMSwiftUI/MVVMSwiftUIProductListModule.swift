import ImageCacheKit
import ProductDomain
import ProductListInterface
import ProductListMVVM
import SwiftUI
import UIKit

@MainActor
public struct MVVMSwiftUIProductListModule: ProductListInterface {
    private let fetchProducts: any FetchProductsUseCase
    private let imageLoader: any ImageLoaderInterface
    private let onSelectProduct: (String, UINavigationController?) -> Void

    public init(
        fetchProducts: any FetchProductsUseCase,
        imageLoader: any ImageLoaderInterface,
        onSelectProduct: @escaping (String, UINavigationController?) -> Void
    ) {
        self.fetchProducts = fetchProducts
        self.imageLoader = imageLoader
        self.onSelectProduct = onSelectProduct
    }

    public func createModule(navigationController: UINavigationController?) -> UIViewController {
        let viewModel = ProductListViewModel(fetchProducts: fetchProducts)
        viewModel.onSelectProduct = { [onSelectProduct] id in
            onSelectProduct(id, navigationController)
        }
        return UIHostingController(
            rootView: ProductListView(viewModel: viewModel, imageLoader: imageLoader)
        )
    }
}
