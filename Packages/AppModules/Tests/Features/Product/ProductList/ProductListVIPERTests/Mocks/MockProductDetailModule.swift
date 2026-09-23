import ProductDetailInterface
import UIKit

final class MockProductDetailModule: ProductDetailInterface {
    var invokedCreateModule = false
    var invokedCreateModuleCount = 0
    var invokedCreateModuleParameters: (navigationController: UINavigationController?, productID: String)?
    var invokedCreateModuleParametersList: [(navigationController: UINavigationController?, productID: String)] = []
    var stubbedCreateModuleResult: UIViewController!

    func createModule(navigationController: UINavigationController?, productID: String) -> UIViewController {
        invokedCreateModule = true
        invokedCreateModuleCount += 1
        invokedCreateModuleParameters = (navigationController, productID)
        invokedCreateModuleParametersList.append((navigationController, productID))
        return stubbedCreateModuleResult
    }
}
