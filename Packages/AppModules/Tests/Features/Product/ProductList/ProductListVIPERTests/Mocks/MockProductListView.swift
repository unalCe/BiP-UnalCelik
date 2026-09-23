import CommonKit
import ProductPresentation
@testable import ProductListVIPER

final class MockProductListView: ProductListViewInterface {
    var invokedPresenterSetter = false
    var invokedPresenterSetterCount = 0
    var invokedPresenter: ProductListPresenterInterface?
    var invokedPresenterList: [ProductListPresenterInterface?] = []
    var invokedPresenterGetter = false
    var invokedPresenterGetterCount = 0
    var stubbedPresenter: ProductListPresenterInterface!

    var presenter: ProductListPresenterInterface? {
        set {
            invokedPresenterSetter = true
            invokedPresenterSetterCount += 1
            invokedPresenter = newValue
            invokedPresenterList.append(newValue)
        }
        get {
            invokedPresenterGetter = true
            invokedPresenterGetterCount += 1
            return stubbedPresenter
        }
    }

    var invokedDisplay = false
    var invokedDisplayCount = 0
    var invokedDisplayParameters: (state: ViewState<[ProductDisplayModel]>, Void)?
    var invokedDisplayParametersList: [(state: ViewState<[ProductDisplayModel]>, Void)] = []

    func display(_ state: ViewState<[ProductDisplayModel]>) {
        invokedDisplay = true
        invokedDisplayCount += 1
        invokedDisplayParameters = (state, ())
        invokedDisplayParametersList.append((state, ()))
    }
}
