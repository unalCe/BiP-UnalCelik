import CommonKit
import CommonUI
import LayoutKit
import UIKit

// TODO: collection view mirroring the MVVM screen
@MainActor
public final class ProductListViewController: UIViewController, ProductListViewInterface {
    public var presenter: ProductListPresenterInterface?

    private lazy var stateView: StateContainerView = {
        let view = StateContainerView()
        view.onRetry = { [weak self] in self?.presenter?.didTapRetry() }
        return view
    }()
    private var items: [ProductDisplayModel] = []

    public init() {
        super.init(nibName: nil, bundle: nil)
        title = AppStrings.ProductList.title
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setUpHierarchy()
        presenter?.viewDidLoad()
    }

    private func setUpHierarchy() {
        view.addSubview(stateView, pinnedToEdges: .zero)
    }

    public func display(_ state: ViewState<[ProductDisplayModel]>) {
        switch state {
        case .idle:
            stateView.hide()
        case .loading:
            stateView.showLoading()
        case .loaded(let items):
            self.items = items
            stateView.hide()
            // TODO: reload collection view
        case .empty:
            stateView.showMessage(AppStrings.ProductList.emptyTitle, retryable: true)
        case .failed(let error):
            stateView.showMessage("\(error.title)\n\(error.message)", retryable: true)
        }
    }
}
