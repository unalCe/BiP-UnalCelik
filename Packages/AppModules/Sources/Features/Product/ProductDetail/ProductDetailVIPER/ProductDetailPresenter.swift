import CommonKit
import Foundation

@MainActor
public final class ProductDetailPresenter: ProductDetailPresenterInterface {
    public weak var view: ProductDetailViewInterface?

    private let productID: String
    private let interactor: ProductDetailInteractorInterface
    private let router: ProductDetailRouterInterface
    private let errorPresenter: ErrorPresenter

    /// The load in flight. Internal so a test can `await loadTask?.value`
    /// instead of sleeping until the state changes.
    private(set) var loadTask: Task<Void, Never>?

    // MARK: - Lifecycle

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

    // MARK: - Public Funcs

    public func viewDidLoad() { load() }

    public func didTapRetry() { load() }

    public func didTapClose() { router.dismiss() }

    // MARK: - Private Funcs

    private func load() {
        loadTask?.cancel()
        view?.display(.loading)

        // `self` is only re-acquired after the await, so a screen dismissed
        // mid-request is released instead of kept alive by its own load
        loadTask = Task { [weak self, interactor, productID] in
            do {
                let item = try await interactor.loadProduct(id: productID)
                guard let self, !Task.isCancelled else { return }
                self.view?.display(.loaded(item))
            } catch {
                guard let self, !Task.isCancelled else { return }
                self.view?.display(.failed(self.errorPresenter.display(for: error)))
            }
        }
    }
}
