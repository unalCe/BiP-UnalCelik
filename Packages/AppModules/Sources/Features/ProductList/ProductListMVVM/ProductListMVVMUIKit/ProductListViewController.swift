import Combine
import CommonKit
import CommonUI
import ImageCacheKit
import ProductListMVVM
import LayoutKit
import UIKit

@MainActor
public final class ProductListViewController: UIViewController {
    private enum Section { case products }

    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, String>
    private typealias DataSource = UICollectionViewDiffableDataSource<Section, String>

    private let viewModel: ProductListViewModel
    private var cancellables = Set<AnyCancellable>()

    private var itemsByID: [String: ProductDisplayModel] = [:]
    private var hasAppliedSnapshot = false

    // MARK: - Subviews
    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: ProductListLayout.make())
        view.backgroundColor = .systemBackground
        view.alwaysBounceVertical = true
        view.delegate = self
        return view
    }()

    private lazy var stateView: StateContainerView = {
        let view = StateContainerView()
        view.onRetry = { [weak self] in self?.viewModel.retry() }
        return view
    }()

    /// Built here, not lazily: UIKit traps if a registration is first created
    /// inside the cell provider. Capturing `imageLoader` rather than `self`
    /// is what lets it be a `let`.
    private let cellRegistration: UICollectionView.CellRegistration<ProductListCell, ProductDisplayModel>

    private lazy var dataSource = DataSource(
        collectionView: collectionView
    ) { [weak self] collectionView, indexPath, id in
        guard let self, let item = self.itemsByID[id] else { return nil }
        return collectionView.dequeueConfiguredReusableCell(
            using: self.cellRegistration,
            for: indexPath,
            item: item
        )
    }

    public init(viewModel: ProductListViewModel,
                imageLoader: any ImageLoaderInterface) {
        self.viewModel = viewModel
        self.cellRegistration = UICollectionView.CellRegistration { cell, _, item in
            cell.configure(with: item,
                           imageLoader: imageLoader)
        }
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
        view.addSubview(collectionView, pinnedToEdges: .zero)
        view.addSubview(stateView, pinnedToEdges: .zero)
    }

    private func bind() {
        viewModel.$state
            .sink { [weak self] state in self?.render(state) }
            .store(in: &cancellables)
    }

    private func render(_ state: ViewState<[ProductDisplayModel]>) {
        collectionView.isHidden = state.value == nil

        switch state {
        case .idle:
            stateView.hide()
        case .loading:
            stateView.showLoading()
        case .loaded(let items):
            stateView.hide()
            apply(items)
        case .empty:
            stateView.showMessage("No products available.", retryable: true)
        case .failed(let error):
            stateView.showMessage("\(error.title)\n\(error.message)", retryable: error.isRetryable)
        }
    }

    private func apply(_ items: [ProductDisplayModel]) {
        // Duplicate identifiers are a hard crash inside `appendItems`.
        var unique: [ProductDisplayModel] = []
        var seen = Set<String>()
        for item in items where seen.insert(item.id).inserted { unique.append(item) }

        let previous = itemsByID
        itemsByID = Dictionary(uniqueKeysWithValues: unique.map { ($0.id, $0) })

        var snapshot = Snapshot()
        snapshot.appendSections([.products])
        snapshot.appendItems(unique.map(\.id), toSection: .products)

        let changed = unique
            .filter { previous[$0.id] != nil && previous[$0.id] != $0 }
            .map(\.id)
        if !changed.isEmpty { snapshot.reconfigureItems(changed) }

        dataSource.apply(snapshot, animatingDifferences: hasAppliedSnapshot)
        hasAppliedSnapshot = true
    }
}

// MARK: - UICollectionViewDelegate

extension ProductListViewController: UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView,
                               didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        guard let id = dataSource.itemIdentifier(for: indexPath) else { return }
        viewModel.didSelectItem(id: id)
    }
}
