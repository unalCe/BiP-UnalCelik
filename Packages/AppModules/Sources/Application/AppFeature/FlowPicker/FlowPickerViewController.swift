import DependencyEngine
import ProductListInterface
import UIKit

/// TODO: proper layout
@MainActor
public final class FlowPickerViewController: UIViewController {
    private var selection = FlowSelection() {
        didSet { renderSelection() }
    }

    private let engine: DependencyEngine
    private let architectureControl = UISegmentedControl(
        items: ArchitectureStyle.allCases.map(\.title)
    )
    private let frameworkControl = UISegmentedControl(items: UIFramework.allCases.map(\.title))
    private let lockLabel = UILabel()
    private let openButton = UIButton(type: .system)

    public init(engine: DependencyEngine = .shared) {
        self.engine = engine
        super.init(nibName: nil, bundle: nil)
        title = "Case Study"
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
        architectureControl.addTarget(self, action: #selector(architectureChanged), for: .valueChanged)
        frameworkControl.addTarget(self, action: #selector(frameworkChanged), for: .valueChanged)

        openButton.addTarget(self, action: #selector(openTapped), for: .touchUpInside)
        openButton.configuration = .filled()

        lockLabel.numberOfLines = 0
        lockLabel.font = .preferredFont(forTextStyle: .footnote)
        lockLabel.textColor = .secondaryLabel

        let stack = UIStackView(arrangedSubviews: [
            architectureControl, frameworkControl, lockLabel, openButton,
        ])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
        ])
    }

    private func renderSelection() {
        architectureControl.selectedSegmentIndex =
            ArchitectureStyle.allCases.firstIndex(of: selection.architecture) ?? 0
        frameworkControl.selectedSegmentIndex =
            UIFramework.allCases.firstIndex(of: selection.uiFramework) ?? 0

        frameworkControl.isEnabled = selection.isUIFrameworkSelectable
        lockLabel.text = selection.lockReason
        lockLabel.isHidden = selection.lockReason == nil
        openButton.setTitle("Open \(selection.style.title)", for: .normal)
    }

    @objc private func architectureChanged() {
        selection.select(ArchitectureStyle.allCases[architectureControl.selectedSegmentIndex])
    }

    @objc private func frameworkChanged() {
        selection.select(UIFramework.allCases[frameworkControl.selectedSegmentIndex])
    }

    @objc private func openTapped() {
        FlowRegistration.register(selection.style, to: engine)

        guard let module: any ProductListInterface =
                engine.resolve((any ProductListInterface).self) else { return }

        let navigationController = UINavigationController()
        let root = module.createModule(navigationController: navigationController)
        navigationController.setViewControllers([root], animated: false)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true)
    }
}
