import DependencyEngine
import ImageCacheKit
import PerformanceKit
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
            let repository: any ProductRepositoryInterface =
                engine.resolve((any ProductRepositoryInterface).self),
            let imageLoader: any ImageLoaderInterface =
                engine.resolve((any ImageLoaderInterface).self),
            let prefetcher: any ImagePrefetchingInterface =
                engine.resolve((any ImagePrefetchingInterface).self)
        else {
            fatalError("Run AppDependencyRegistration before registering a flow")
        }

        // Typed apart from the `??`: inline, `resolve` infers its generic as
        // `NoopPerformanceTracer`, the cast fails, and the no-op always wins.
        let registeredTracer: (any PerformanceTracing)? = engine.resolve((any PerformanceTracing).self)
        let tracer = registeredTracer ?? NoopPerformanceTracer()

        let fetchProducts = FetchProducts(repository: repository)
        let fetchDetail = FetchProductDetail(repository: repository)

        let detail: any ProductDetailInterface
        let list: any ProductListInterface

        switch style {
        case .mvvmUIKit:
            detail = MVVMUIKitProductDetailModule(fetchDetail: fetchDetail, imageLoader: imageLoader)
            list = MVVMUIKitProductListModule(
                fetchProducts: fetchProducts,
                imageLoader: imageLoader,
                prefetcher: prefetcher,
                tracer: tracer,
                onSelectProduct: Self.push(detail)
            )

        case .mvvmSwiftUI:
            detail = MVVMSwiftUIProductDetailModule(fetchDetail: fetchDetail, imageLoader: imageLoader)
            list = MVVMSwiftUIProductListModule(
                fetchProducts: fetchProducts,
                imageLoader: imageLoader,
                prefetcher: prefetcher,
                onSelectProduct: Self.push(detail)
            )

        case .viperUIKit:
            detail = VIPERProductDetailModule(fetchDetail: fetchDetail)
            list = VIPERProductListModule(fetchProducts: fetchProducts)
        }

        engine.register(value: detail, for: (any ProductDetailInterface).self)
        engine.register(value: list, for: (any ProductListInterface).self)
    }

    private static func push(
        _ detail: any ProductDetailInterface
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
