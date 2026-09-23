import ProductListInterface
import UIKit

@MainActor
final class MockProductListScreenFactory: ProductListScreenFactory {
    var invokedMakeScreen = false
    var invokedMakeScreenCount = 0
    var invokedMakeScreenParameters: (onSelectProduct: (String) -> Void, Void)?
    var invokedMakeScreenParametersList: [(onSelectProduct: (String) -> Void, Void)] = []
    var stubbedMakeScreenResult = UIViewController()

    func makeScreen(onSelectProduct: @escaping (String) -> Void) -> UIViewController {
        invokedMakeScreen = true
        invokedMakeScreenCount += 1
        invokedMakeScreenParameters = (onSelectProduct, ())
        invokedMakeScreenParametersList.append((onSelectProduct, ()))
        return stubbedMakeScreenResult
    }
}
