import ProductListInterface
import UIKit

@MainActor
final class MockProductListModule: ProductListInterface {
    var invokedCreateModule = false
    var invokedCreateModuleCount = 0
    var invokedCreateModuleParameters: (navigationController: UINavigationController?, Void)?
    var invokedCreateModuleParametersList: [(navigationController: UINavigationController?, Void)] = []
    var stubbedCreateModuleResult = UIViewController()

    func createModule(navigationController: UINavigationController?) -> UIViewController {
        invokedCreateModule = true
        invokedCreateModuleCount += 1
        invokedCreateModuleParameters = (navigationController, ())
        invokedCreateModuleParametersList.append((navigationController, ()))
        return stubbedCreateModuleResult
    }
}
