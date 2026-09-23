import ImageCacheKit
import ProductDetailInterface
import ProductDetailMVVM
import ProductDomain
import SwiftUI
import UIKit

@MainActor
public struct MVVMSwiftUIProductDetailModule: ProductDetailScreenFactory {
    private let fetchDetail: FetchProductDetailUseCase
    private let imageLoader: ImageLoaderInterface

    public init(fetchDetail: FetchProductDetailUseCase, imageLoader: ImageLoaderInterface) {
        self.fetchDetail = fetchDetail
        self.imageLoader = imageLoader
    }

    public func makeScreen(productID: String, onFinish: @escaping () -> Void) -> UIViewController {
        let viewModel = ProductDetailViewModel(productID: productID, fetchDetail: fetchDetail)
        viewModel.onFinish = onFinish
        return UIHostingController(
            rootView: ProductDetailView(viewModel: viewModel, imageLoader: imageLoader)
        )
    }
}
