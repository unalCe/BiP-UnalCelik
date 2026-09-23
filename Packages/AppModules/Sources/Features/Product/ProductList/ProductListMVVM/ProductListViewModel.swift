import Combine
import CommonKit
import Foundation
import ProductDomain
import ProductPresentation

@MainActor
public final class ProductListViewModel: ObservableObject {
    @Published public private(set) var state: ViewState<[ProductDisplayModel]> = .idle

    public var onSelectProduct: ((String) -> Void)?

    private let fetchProducts: FetchProductsUseCase
    private let mapper: ProductDisplayMapper
    private let errorPresenter: ErrorPresenter

    /// The load in flight. Internal so a test can `await loadTask?.value`
    /// instead of sleeping until the state changes.
    private(set) var loadTask: Task<Void, Never>?

    // MARK: - Lifecycle

    public init(
        fetchProducts: FetchProductsUseCase,
        mapper: ProductDisplayMapper = ProductDisplayMapper(),
        errorPresenter: ErrorPresenter = ErrorPresenter()
    ) {
        self.fetchProducts = fetchProducts
        self.mapper = mapper
        self.errorPresenter = errorPresenter
    }

    // MARK: - Public Funcs

    public func onAppear() {
        guard state.isIdle else { return }
        load()
    }

    public func retry() { load() }

    public func didSelectItem(id: String) {
        onSelectProduct?(id)
    }

    // MARK: - Private Funcs

    private func load() {
        loadTask?.cancel()
        state = .loading

        // `self` is only re-acquired after the await, so a screen dismissed
        // mid-request is released instead of kept alive by its own load
        loadTask = Task { [weak self, fetchProducts] in
            do {
                let products = try await fetchProducts.execute()
                guard let self, !Task.isCancelled else { return }
                let items = self.mapper.map(products)
                self.state = items.isEmpty ? .empty : .loaded(items)
            } catch {
                guard let self, !Task.isCancelled else { return }
                self.state = .failed(self.errorPresenter.display(for: error))
            }
        }
    }
}
