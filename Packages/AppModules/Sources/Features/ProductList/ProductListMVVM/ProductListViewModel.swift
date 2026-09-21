import Combine
import CommonKit
import Foundation
import ProductDomain

@MainActor
public final class ProductListViewModel: ObservableObject {
    @Published public private(set) var state: ViewState<[ProductDisplayModel]> = .idle

    public var onSelectProduct: ((String) -> Void)?

    private let fetchProducts: any FetchProductsUseCase
    private let mapper: ProductDisplayMapper
    private let errorPresenter: ErrorPresenter

    private var items: [ProductDisplayModel] = []
    private var loadTask: Task<Void, Never>?

    public init(
        fetchProducts: any FetchProductsUseCase,
        mapper: ProductDisplayMapper = ProductDisplayMapper(),
        errorPresenter: ErrorPresenter = ErrorPresenter()
    ) {
        self.fetchProducts = fetchProducts
        self.mapper = mapper
        self.errorPresenter = errorPresenter
    }

    // MARK: - Input

    public func onAppear() {
        guard state.isIdle else { return }
        load()
    }

    public func retry() { load() }

    public func didSelectItem(at index: Int) {
        guard items.indices.contains(index) else { return }
        onSelectProduct?(items[index].id)
    }

    public func didSelectItem(id: String) {
        onSelectProduct?(id)
    }

    // MARK: - Work

    private func load() {
        loadTask?.cancel()
        state = .loading

        loadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let products = try await self.fetchProducts.execute()
                guard !Task.isCancelled else { return }
                self.items = self.mapper.map(products)
                self.state = self.items.isEmpty ? .empty : .loaded(self.items)
            } catch {
                guard !Task.isCancelled else { return }
                self.state = .failed(self.errorPresenter.display(for: error))
            }
        }
    }
}
