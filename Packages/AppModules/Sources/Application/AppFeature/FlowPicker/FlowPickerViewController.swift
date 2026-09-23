import CommonKit
import DependencyEngine
import LayoutKit
import LoggingKit
import LoggingKitLive
import ProductListInterface
import UIKit

/// TODO: proper layout
@MainActor
public final class FlowPickerViewController: UIViewController {
    private enum Metrics {
        static let spacing: CGFloat = 16
        static let horizontalInset: CGFloat = 24
    }

    private var selection = FlowSelection() {
        didSet { renderSelection() }
    }

    private let engine: DependencyEngine
    private let logger: LoggerInterface

    private lazy var architectureControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ArchitectureStyle.allCases.map(\.title))
        control.addTarget(self, action: #selector(architectureChanged), for: .valueChanged)
        return control
    }()

    private lazy var frameworkControl: UISegmentedControl = {
        let control = UISegmentedControl(items: UIFramework.allCases.map(\.title))
        control.addTarget(self, action: #selector(frameworkChanged), for: .valueChanged)
        return control
    }()

    private let lockLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .preferredFont(forTextStyle: .footnote)
        label.textColor = .secondaryLabel
        return label
    }()

    private lazy var openButton: UIButton = {
        let button = UIButton(type: .system)
        button.configuration = .filled()
        button.addTarget(self, action: #selector(openTapped), for: .touchUpInside)
        return button
    }()

    private lazy var stack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [
            architectureControl, frameworkControl, lockLabel, openButton,
        ])
        stack.axis = .vertical
        stack.spacing = Metrics.spacing
        return stack
    }()

    public init(engine: DependencyEngine = .shared, logger: LoggerInterface = OSLogger()) {
        self.engine = engine
        self.logger = logger
        super.init(nibName: nil, bundle: nil)
        title = AppStrings.FlowPicker.title
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setUpHierarchy()
        renderSelection()
    }

    private func setUpHierarchy() {
        view.addSubview(stack) {
            $0.centerY(to: view).pinHorizontally(to: view, insets: .horizontal(Metrics.horizontalInset))
        }
    }

    private func renderSelection() {
        architectureControl.selectedSegmentIndex =
            ArchitectureStyle.allCases.firstIndex(of: selection.architecture) ?? 0
        frameworkControl.selectedSegmentIndex =
            UIFramework.allCases.firstIndex(of: selection.uiFramework) ?? 0

        frameworkControl.isEnabled = selection.isUIFrameworkSelectable
        lockLabel.text = selection.lockReason
        lockLabel.isHidden = selection.lockReason == nil
        openButton.setTitle(AppStrings.FlowPicker.open(selection.style.title), for: .normal)
    }

    @objc private func architectureChanged() {
        selection.select(ArchitectureStyle.allCases[architectureControl.selectedSegmentIndex])
    }

    @objc private func frameworkChanged() {
        selection.select(UIFramework.allCases[frameworkControl.selectedSegmentIndex])
    }

    @objc private func openTapped() {
        FlowRegistration.register(selection.style, to: engine)

        // a wiring bug, not a user error: loud in debug, a logged no-op in release
        guard let module: ProductListInterface =
                engine.resolve(ProductListInterface.self) else {
            let message = "no ProductListInterface registered for \(selection.style)"
            logger.error(message, category: .composition)
            assertionFailure(message)
            return
        }

        let navigationController = UINavigationController()
        let root = module.createModule(navigationController: navigationController)
        navigationController.setViewControllers([root], animated: false)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true)
    }
}
