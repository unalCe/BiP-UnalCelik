import CommonKit
import Foundation
import ProductPresentation

@MainActor
public final class ProductListPresenter: ProductListPresenterInterface {
    public weak var view: ProductListViewInterface?

    private let interactor: ProductListInteractorInterface
    private let router: ProductListRouterInterface
    private let errorPresenter: ErrorPresenter

    private var items: [ProductDisplayModel] = []
    /// The load in flight. Internal so a test can `await loadTask?.value`
    /// instead of sleeping until the state changes.
    private(set) var loadTask: Task<Void, Never>?

    // MARK: - Lifecycle

    public init(
        interactor: ProductListInteractorInterface,
        router: ProductListRouterInterface,
        errorPresenter: ErrorPresenter = ErrorPresenter()
    ) {
        self.interactor = interactor
        self.router = router
        self.errorPresenter = errorPresenter
    }

    // MARK: - Public Funcs

    public func viewDidLoad() { load() }

    public func didTapRetry() { load() }

    public func didSelectItem(id: String) {
        guard items.contains(where: { $0.id == id }) else { return }
        router.routeToDetail(productID: id)
    }

    // MARK: - Private Funcs

    private func load() {
        loadTask?.cancel()
        view?.display(.loading)

        // `self` is only re-acquired after the await, so a screen dismissed
        // mid-request is released instead of kept alive by its own load
        loadTask = Task { [weak self, interactor] in
            do {
                let items = try await interactor.loadProducts()
                guard let self, !Task.isCancelled else { return }
                self.items = items
                self.view?.display(items.isEmpty ? .empty : .loaded(items))
            } catch {
                guard let self, !Task.isCancelled else { return }
                self.view?.display(.failed(self.errorPresenter.display(for: error)))
            }
        }
    }
}
