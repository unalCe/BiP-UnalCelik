import Combine
import CommonKit
import Foundation
import ProductDomain

@MainActor
public final class ProductDetailViewModel: ObservableObject {
    @Published public private(set) var state: ViewState<ProductDisplayModel> = .idle

    public var onFinish: (() -> Void)?

    private let productID: String
    private let fetchDetail: any FetchProductDetailUseCase
    private let mapper: ProductDisplayMapper
    private let errorPresenter: ErrorPresenter

    private var loadTask: Task<Void, Never>?

    public init(
        productID: String,
        fetchDetail: any FetchProductDetailUseCase,
        mapper: ProductDisplayMapper = ProductDisplayMapper(),
        errorPresenter: ErrorPresenter = ErrorPresenter()
    ) {
        self.productID = productID
        self.fetchDetail = fetchDetail
        self.mapper = mapper
        self.errorPresenter = errorPresenter
    }

    public func onAppear() {
        guard state.isIdle else { return }
        load()
    }

    public func retry() { load() }

    public func close() { onFinish?() }

    private func load() {
        loadTask?.cancel()
        state = .loading

        loadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let product = try await self.fetchDetail.execute(id: self.productID)
                guard !Task.isCancelled else { return }
                self.state = .loaded(self.mapper.map(product))
            } catch {
                guard !Task.isCancelled else { return }
                self.state = .failed(self.errorPresenter.display(for: error))
            }
        }
    }
}
