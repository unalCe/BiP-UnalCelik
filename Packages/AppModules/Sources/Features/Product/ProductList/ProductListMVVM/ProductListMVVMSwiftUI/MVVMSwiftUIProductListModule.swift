import ImageCacheKit
import ProductDomain
import ProductListInterface
import ProductListMVVM
import SwiftUI
import UIKit

@MainActor
public struct MVVMSwiftUIProductListModule: ProductListScreenFactory {
    private let fetchProducts: FetchProductsUseCase
    private let imageLoader: ImageLoaderInterface

    public init(fetchProducts: FetchProductsUseCase, imageLoader: ImageLoaderInterface) {
        self.fetchProducts = fetchProducts
        self.imageLoader = imageLoader
    }

    public func makeScreen(onSelectProduct: @escaping (String) -> Void) -> UIViewController {
        let viewModel = ProductListViewModel(fetchProducts: fetchProducts)
        viewModel.onSelectProduct = onSelectProduct
        return UIHostingController(
            rootView: ProductListView(viewModel: viewModel, imageLoader: imageLoader)
        )
    }
}
