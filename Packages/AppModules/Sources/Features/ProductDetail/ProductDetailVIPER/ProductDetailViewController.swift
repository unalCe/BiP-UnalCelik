import CommonKit
import CommonUI
import LayoutKit
import UIKit

/// TODO: mirror the MVVM detail layout
@MainActor
public final class ProductDetailViewController: UIViewController, ProductDetailViewInterface {
    public var presenter: (any ProductDetailPresenterInterface)?

    private let stateView = StateContainerView()

    public init() {
        super.init(nibName: nil, bundle: nil)
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
        stateView.onRetry = { [weak self] in self?.presenter?.didTapRetry() }
        view.addSubview(stateView, pinnedToEdges: .zero)
    }

    public func display(_ state: ViewState<ProductDisplayModel>) {
        switch state {
        case .idle:
            stateView.hide()
        case .loading:
            stateView.showLoading()
        case .loaded(let item):
            title = item.title
            stateView.hide()
            // TODO: populate
        case .empty:
            stateView.showMessage("Not available.", retryable: false)
        case .failed(let error):
            stateView.showMessage("\(error.title)\n\(error.message)", retryable: error.isRetryable)
        }
    }
}
