import ProductDetailInterface
import UIKit

@MainActor
final class MockProductDetailScreenFactory: ProductDetailScreenFactory {
    var invokedMakeScreen = false
    var invokedMakeScreenCount = 0
    var invokedMakeScreenParameters: (productID: String, onFinish: () -> Void)?
    var invokedMakeScreenParametersList: [(productID: String, onFinish: () -> Void)] = []
    var stubbedMakeScreenResult = UIViewController()

    func makeScreen(productID: String, onFinish: @escaping () -> Void) -> UIViewController {
        invokedMakeScreen = true
        invokedMakeScreenCount += 1
        invokedMakeScreenParameters = (productID, onFinish)
        invokedMakeScreenParametersList.append((productID, onFinish))
        return stubbedMakeScreenResult
    }
}
