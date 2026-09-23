import AccessibilityIdentifiers
import AccessibilityKit
import CommonKit
import DependencyEngine
import LayoutKit
import LoggingKit
import UIKit

/// Hosts the running flow and swaps it for another on request.

@MainActor
final class AppShellViewController: UIViewController {
    private let engine: DependencyEngine
    private let logger: LoggerInterface

    private(set) var currentStyle: FlowStyle
    /// Retained here: screens hold their coordinator only weakly.
    private(set) var coordinator: FlowCoordinator?

    var flowController: UINavigationController? { coordinator?.navigationController }

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
        let next = FlowRegistration.makeCoordinator(for: style, engine: engine)
        next.start()

        guard let root = next.navigationController.viewControllers.first else {
            let message = "coordinator for \(style) started without a root screen"
            logger.error(message, category: .composition)
            assertionFailure(message)
            return
        }
        root.navigationItem.rightBarButtonItem = makeInfoButton()

        replaceFlow(with: next)
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
        button.setAccessibilityIdentifier(UIElements.Shell.flowPickerButton)
        return button
    }

    private func replaceFlow(with next: FlowCoordinator) {
        let previous = flowController
        let nextController = next.navigationController

        previous?.willMove(toParent: nil)
        addChild(nextController)
        view.addSubview(nextController.view, pinnedToEdges: .zero)
        nextController.didMove(toParent: self)
        coordinator = next

        guard let previous else { return }
        nextController.view.alpha = 0
        UIView.animate(withDuration: 0.3) {
            nextController.view.alpha = 1
        } completion: { _ in
            previous.view.removeFromSuperview()
            previous.removeFromParent()
        }
    }
}
