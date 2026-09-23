import ProductListInterface
import UIKit

// Only sets the root. In VIPER, navigation belongs to each module's Router by definition, so transitions stay there; this type exists so the shell can start every flow the same way.
@MainActor
final class VIPERFlowCoordinator: FlowCoordinator {
    let navigationController = UINavigationController()

    private let list: ProductListInterface

    init(list: ProductListInterface) {
        self.list = list
    }

    func start() {
        let root = list.createModule(navigationController: navigationController)
        navigationController.setViewControllers([root], animated: false)
    }
}
