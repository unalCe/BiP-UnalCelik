import UIKit

@MainActor
public final class ProductDetailRouter: ProductDetailRouterInterface {
    public weak var navigationController: UINavigationController?

    public init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }

    public func dismiss() {
        navigationController?.popViewController(animated: true)
    }
}
