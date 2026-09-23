import ProductDetailInterface
import ProductListInterface
import UIKit

// Owns the navigation stack and every transition in the product flow; the screens it builds only report intents (`onSelectProduct`, `onFinish`)
@MainActor
final class ProductFlowCoordinator: FlowCoordinator {
    let navigationController = UINavigationController()

    private let list: ProductListScreenFactory
    private let detail: ProductDetailScreenFactory

    init(list: ProductListScreenFactory,
         detail: ProductDetailScreenFactory) {
        self.list = list
        self.detail = detail
    }

    func start() {
        let root = list.makeScreen { [weak self] productID in
            self?.showDetail(productID: productID)
        }
        navigationController.setViewControllers([root], animated: false)
    }

    func showDetail(productID: String) {
        let screen = detail.makeScreen(productID: productID) { [weak self] in
            self?.finishDetail()
        }
        navigationController.pushViewController(screen, animated: true)
    }

    func finishDetail() {
        navigationController.popViewController(animated: true)
    }
}
