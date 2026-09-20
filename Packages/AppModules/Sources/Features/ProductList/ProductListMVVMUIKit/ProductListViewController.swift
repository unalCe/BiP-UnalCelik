import Combine
import CommonKit
import CommonUI
import ImageCacheKit
import ProductListMVVM
import UIKit

/// TODO: compositional layout + diffable data source, prefetch data source
/// wired to `viewModel.prefetchItems(at:)`
@MainActor
public final class ProductListViewController: UIViewController {
    private let viewModel: ProductListViewModel
    private let imageLoader: any ImageLoaderInterface
    private let stateView = StateContainerView()
    private var cancellables = Set<AnyCancellable>()

    public init(viewModel: ProductListViewModel, imageLoader: any ImageLoaderInterface) {
        self.viewModel = viewModel
        self.imageLoader = imageLoader
        super.init(nibName: nil, bundle: nil)
        title = "Products"
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setUpHierarchy()
        bind()
        viewModel.onAppear()
    }

    private func setUpHierarchy() {
        stateView.onRetry = { [weak self] in self?.viewModel.retry() }
        stateView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stateView)
        NSLayoutConstraint.activate([
            stateView.topAnchor.constraint(equalTo: view.topAnchor),
            stateView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stateView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stateView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
    }

    private func bind() {
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in self?.render(state) }
            .store(in: &cancellables)
    }

    private func render(_ state: ViewState<[ProductDisplayModel]>) {
        switch state {
        case .idle:
            stateView.hide()
        case .loading:
            stateView.showLoading()
        case .loaded:
            stateView.hide()
            // TODO: apply diffable snapshot
        case .empty:
            stateView.showMessage("No products available.", retryable: true)
        case .failed(let error):
            stateView.showMessage("\(error.title)\n\(error.message)", retryable: error.isRetryable)
        }
    }
}
