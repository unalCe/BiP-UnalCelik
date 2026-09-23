@testable import ProductListVIPER

final class MockProductListRouter: ProductListRouterInterface {
    var invokedRouteToDetail = false
    var invokedRouteToDetailCount = 0
    var invokedRouteToDetailParameters: (productID: String, Void)?
    var invokedRouteToDetailParametersList: [(productID: String, Void)] = []

    func routeToDetail(productID: String) {
        invokedRouteToDetail = true
        invokedRouteToDetailCount += 1
        invokedRouteToDetailParameters = (productID, ())
        invokedRouteToDetailParametersList.append((productID, ()))
    }
}
