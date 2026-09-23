import CommonKit
import DependencyEngine
import LayoutKit
import LoggingKit
import ProductListInterface
import UIKit

/// Hosts the running flow and swaps it for another on request.

@MainActor
final class AppShellViewController: UIViewController {
    private let engine: DependencyEngine
    private let logger: LoggerInterface

    private(set) var currentStyle: FlowStyle
    private(set) var flowController: UINavigationController?

    // MARK: - Lifecycle

    init(style: FlowStyle,
         engine: DependencyEngine,
         logger: LoggerInterface) {
        self.currentStyle = style
        self.engine = engine
        self.logger = logger
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        start(currentStyle)
    }

    // MARK: - Internal Funcs

    func start(_ style: FlowStyle) {
        FlowRegistration.register(style, to: engine)

        guard let module: ProductListInterface =
                engine.resolve(ProductListInterface.self) else {
            let message = "no ProductListInterface registered for \(style)"
            logger.error(message, category: .composition)
            assertionFailure(message)
            return
        }

        let navigationController = UINavigationController()
        let root = module.createModule(navigationController: navigationController)
        root.navigationItem.rightBarButtonItem = makeInfoButton()
        navigationController.setViewControllers([root], animated: false)

        replaceFlow(with: navigationController)
        currentStyle = style
    }

    @objc func showFlowPicker() {
        let picker = FlowPickerViewController(currentStyle: currentStyle) { [weak self] style in
            self?.dismiss(animated: true) { self?.start(style) }
        }
        let navigationController = UINavigationController(rootViewController: picker)
        navigationController.sheetPresentationController?.detents = [.medium()]
        navigationController.sheetPresentationController?.prefersGrabberVisible = true
        present(navigationController, animated: true)
    }

    // MARK: - Private Funcs

    private func makeInfoButton() -> UIBarButtonItem {
        let button = UIBarButtonItem(
            image: UIImage(systemName: "info.circle"),
            style: .plain,
            target: self,
            action: #selector(showFlowPicker)
        )
        button.accessibilityLabel = AppStrings.FlowPicker.infoButton
        return button
    }

    private func replaceFlow(with next: UINavigationController) {
        let previous = flowController

        previous?.willMove(toParent: nil)
        addChild(next)
        view.addSubview(next.view, pinnedToEdges: .zero)
        next.didMove(toParent: self)
        flowController = next

        guard let previous else { return }
        next.view.alpha = 0
        UIView.animate(withDuration: 0.3) {
            next.view.alpha = 1
        } completion: { _ in
            previous.view.removeFromSuperview()
            previous.removeFromParent()
        }
    }
}
