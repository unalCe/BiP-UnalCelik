import Combine
import CommonKit
import Foundation
import ProductDomain
import ProductPresentation

@MainActor
public final class ProductDetailViewModel: ObservableObject {
    @Published public private(set) var state: ViewState<ProductDisplayModel> = .idle

    public var onFinish: (() -> Void)?

    private let productID: String
    private let fetchDetail: FetchProductDetailUseCase
    private let mapper: ProductDisplayMapper
    private let errorPresenter: ErrorPresenter

    /// The load in flight. Internal so a test can `await loadTask?.value`
    /// instead of sleeping until the state changes.
    private(set) var loadTask: Task<Void, Never>?

    // MARK: - Lifecycle

    public init(
        productID: String,
        fetchDetail: FetchProductDetailUseCase,
        mapper: ProductDisplayMapper = ProductDisplayMapper(),
        errorPresenter: ErrorPresenter = ErrorPresenter()
    ) {
        self.productID = productID
        self.fetchDetail = fetchDetail
        self.mapper = mapper
        self.errorPresenter = errorPresenter
    }

    // MARK: - Public Funcs

    public func onAppear() {
        guard state.isIdle else { return }
        load()
    }

    public func retry() { load() }

    public func close() { onFinish?() }

    // MARK: - Private Funcs

    private func load() {
        loadTask?.cancel()
        state = .loading

        // `self` is only re-acquired after the await, so a screen dismissed
        // mid-request is released instead of kept alive by its own load
        loadTask = Task { [weak self, fetchDetail, productID] in
            do {
                let product = try await fetchDetail.execute(id: productID)
                guard let self, !Task.isCancelled else { return }
                self.state = .loaded(self.mapper.map(product))
            } catch {
                guard let self, !Task.isCancelled else { return }
                self.state = .failed(self.errorPresenter.display(for: error))
            }
        }
    }
}
