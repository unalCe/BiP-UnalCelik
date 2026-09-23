import CommonKit
import Foundation

@MainActor
public final class ProductDetailPresenter: ProductDetailPresenterInterface {
    public weak var view: ProductDetailViewInterface?

    private let productID: String
    private let interactor: ProductDetailInteractorInterface
    private let router: ProductDetailRouterInterface
    private let errorPresenter: ErrorPresenter

    private var loadTask: Task<Void, Never>?

    public init(
        productID: String,
        interactor: ProductDetailInteractorInterface,
        router: ProductDetailRouterInterface,
        errorPresenter: ErrorPresenter = ErrorPresenter()
    ) {
        self.productID = productID
        self.interactor = interactor
        self.router = router
        self.errorPresenter = errorPresenter
    }

    public func viewDidLoad() { load() }

    public func didTapRetry() { load() }

    public func didTapClose() { router.dismiss() }

    private func load() {
        loadTask?.cancel()
        view?.display(.loading)

        loadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let item = try await self.interactor.loadProduct(id: self.productID)
                guard !Task.isCancelled else { return }
                self.view?.display(.loaded(item))
            } catch {
                guard !Task.isCancelled else { return }
                self.view?.display(.failed(self.errorPresenter.display(for: error)))
            }
        }
    }
}
