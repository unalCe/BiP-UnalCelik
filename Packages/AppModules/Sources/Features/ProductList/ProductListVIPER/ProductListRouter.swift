import DependencyEngine
import ProductDetailInterface
import UIKit

@MainActor
public final class ProductListRouter: ProductListRouterInterface {
    public weak var navigationController: UINavigationController?

    @Dependency private var detailModule: ProductDetailInterface

    public init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }

    public init(
        navigationController: UINavigationController?,
        detailModule: ProductDetailInterface
    ) {
        self.navigationController = navigationController
        self._detailModule = Dependency(wrappedValue: detailModule)
    }

    public func routeToDetail(productID: String) {
        let destination = detailModule.createModule(
            navigationController: navigationController,
            productID: productID
        )
        navigationController?.pushViewController(destination, animated: true)
    }
}
