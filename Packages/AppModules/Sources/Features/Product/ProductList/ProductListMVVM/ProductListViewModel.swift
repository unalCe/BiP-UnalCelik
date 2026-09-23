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

    private var loadTask: Task<Void, Never>?

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

        loadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let products = try await self.fetchProducts.execute()
                guard !Task.isCancelled else { return }
                let items = self.mapper.map(products)
                self.state = items.isEmpty ? .empty : .loaded(items)
            } catch {
                guard !Task.isCancelled else { return }
                self.state = .failed(self.errorPresenter.display(for: error))
            }
        }
    }
}
