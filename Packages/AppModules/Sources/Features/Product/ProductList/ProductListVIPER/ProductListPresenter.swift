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
    private var loadTask: Task<Void, Never>?

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

        loadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let items = try await self.interactor.loadProducts()
                guard !Task.isCancelled else { return }
                self.items = items
                self.view?.display(items.isEmpty ? .empty : .loaded(items))
            } catch {
                guard !Task.isCancelled else { return }
                self.view?.display(.failed(self.errorPresenter.display(for: error)))
            }
        }
    }
}
