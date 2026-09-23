import DependencyEngine
import ImageCacheKit
import ProductDetailInterface
import ProductDetailMVVMSwiftUI
import ProductDetailMVVMUIKit
import ProductDetailVIPER
import ProductDomain
import ProductListInterface
import ProductListMVVMSwiftUI
import ProductListMVVMUIKit
import ProductListVIPER
import UIKit

@MainActor
public enum FlowRegistration {
    public static func register(_ style: FlowStyle, to engine: DependencyEngine) {
        guard
            let repository: ProductRepositoryInterface =
                engine.resolve(ProductRepositoryInterface.self),
            let imageLoader: ImageLoaderInterface =
                engine.resolve(ImageLoaderInterface.self),
            let prefetcher: ImagePrefetchingInterface =
                engine.resolve(ImagePrefetchingInterface.self)
        else {
            fatalError("Run AppDependencyRegistration before registering a flow")
        }

        let fetchProducts = FetchProducts(repository: repository)
        let fetchDetail = FetchProductDetail(repository: repository)

        let detail: ProductDetailInterface
        let list: ProductListInterface

        switch style {
        case .mvvmUIKit:
            detail = MVVMUIKitProductDetailModule(fetchDetail: fetchDetail, imageLoader: imageLoader)
            list = MVVMUIKitProductListModule(
                fetchProducts: fetchProducts,
                imageLoader: imageLoader,
                prefetcher: prefetcher,
                onSelectProduct: Self.push(detail)
            )

        case .mvvmSwiftUI:
            detail = MVVMSwiftUIProductDetailModule(fetchDetail: fetchDetail, imageLoader: imageLoader)
            list = MVVMSwiftUIProductListModule(
                fetchProducts: fetchProducts,
                imageLoader: imageLoader,
                onSelectProduct: Self.push(detail)
            )

        case .viperUIKit:
            detail = VIPERProductDetailModule(fetchDetail: fetchDetail, imageLoader: imageLoader)
            list = VIPERProductListModule(fetchProducts: fetchProducts)
        }

        engine.register(value: detail, for: ProductDetailInterface.self)
        engine.register(value: list, for: ProductListInterface.self)
    }

    private static func push(
        _ detail: ProductDetailInterface
    ) -> (String, UINavigationController?) -> Void {
        { productID, navigationController in
            let destination = detail.createModule(
                navigationController: navigationController,
                productID: productID
            )
            navigationController?.pushViewController(destination, animated: true)
        }
    }
}
