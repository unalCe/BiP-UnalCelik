import DependencyEngine
import ImageCacheKit
import ProductDetailInterface
import ProductDetailMVVMSwiftUI
import ProductDetailMVVMUIKit
import ProductDetailVIPER
import ProductDomain
import ProductListMVVMSwiftUI
import ProductListMVVMUIKit
import ProductListVIPER
import UIKit

@MainActor
enum FlowRegistration {
    static func makeCoordinator(for style: FlowStyle,
                                engine: DependencyEngine) -> FlowCoordinator {
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

        switch style {
        case .mvvmUIKit:
            return ProductFlowCoordinator(
                list: MVVMUIKitProductListModule(
                    fetchProducts: fetchProducts,
                    imageLoader: imageLoader,
                    prefetcher: prefetcher
                ),
                detail: MVVMUIKitProductDetailModule(fetchDetail: fetchDetail, imageLoader: imageLoader)
            )

        case .mvvmSwiftUI:
            return ProductFlowCoordinator(
                list: MVVMSwiftUIProductListModule(fetchProducts: fetchProducts, imageLoader: imageLoader),
                detail: MVVMSwiftUIProductDetailModule(fetchDetail: fetchDetail, imageLoader: imageLoader)
            )

        case .viperUIKit:
            let detail: ProductDetailInterface =
                VIPERProductDetailModule(fetchDetail: fetchDetail, imageLoader: imageLoader)
            engine.register(value: detail, for: ProductDetailInterface.self)
            return VIPERFlowCoordinator(
                list: VIPERProductListModule(
                    fetchProducts: fetchProducts,
                    imageLoader: imageLoader,
                    prefetcher: prefetcher
                )
            )
        }
    }
}
