@testable import ProductDetailVIPER

final class MockProductDetailRouter: ProductDetailRouterInterface {
    var invokedDismiss = false
    var invokedDismissCount = 0

    func dismiss() {
        invokedDismiss = true
        invokedDismissCount += 1
    }
}
