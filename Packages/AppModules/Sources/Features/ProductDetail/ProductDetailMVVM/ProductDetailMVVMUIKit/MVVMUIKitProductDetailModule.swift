import ImageCacheKit
import ProductDetailInterface
import ProductDetailMVVM
import ProductDomain
import UIKit

@MainActor
public struct MVVMUIKitProductDetailModule: ProductDetailInterface {
    private let fetchDetail: any FetchProductDetailUseCase
    private let imageLoader: any ImageLoaderInterface

    public init(fetchDetail: any FetchProductDetailUseCase, imageLoader: any ImageLoaderInterface) {
        self.fetchDetail = fetchDetail
        self.imageLoader = imageLoader
    }

    public func createModule(
        navigationController: UINavigationController?,
        productID: String
    ) -> UIViewController {
        let viewModel = ProductDetailViewModel(productID: productID, fetchDetail: fetchDetail)
        viewModel.onFinish = { [weak navigationController] in
            navigationController?.popViewController(animated: true)
        }
        return ProductDetailViewController(viewModel: viewModel, imageLoader: imageLoader)
    }
}
