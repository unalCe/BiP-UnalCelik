import PerformanceKit
import UIKit

/// A small overlay in its own window, above every presented screen, showing
/// the last scroll session and the image wait. Its accessibility value is the
/// full report as JSON — how the UI tests read the numbers out of the app.
@MainActor
public final class PerformanceHUD {
    public static let accessibilityIdentifier = "performance.hud"

    /// A timer, not a push per sample, so the HUD never adds work to the
    /// frames it is measuring. `.default` run-loop mode pauses it while a
    /// scroll is tracking.
    static let refreshInterval: TimeInterval = 0.5

    private static var installed: PerformanceHUD?

    private let tracer: PerformanceTracer
    private var window: UIWindow?
    private var timer: Timer?
    private var activationObserver: (any NSObjectProtocol)?

    private let label: UILabel = {
        let label = UILabel()
        label.font = .monospacedSystemFont(ofSize: 11, weight: .medium)
        label.textColor = .white
        label.numberOfLines = 0
        label.layer.cornerRadius = 6
        label.layer.masksToBounds = true
        label.accessibilityIdentifier = PerformanceHUD.accessibilityIdentifier
        return label
    }()

    private init(tracer: PerformanceTracer) {
        self.tracer = tracer
    }

    /// Once per process. Attaches to the first active window scene, waiting
    /// for one if launch has not got that far.
    public static func install(tracer: PerformanceTracer) {
        guard installed == nil else { return }
        let hud = PerformanceHUD(tracer: tracer)
        installed = hud
        hud.attachWhenSceneIsActive()
    }

    private func attachWhenSceneIsActive() {
        if let scene = Self.activeScene() {
            attach(to: scene)
            return
        }
        activationObserver = NotificationCenter.default.addObserver(
            forName: UIScene.didActivateNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            MainActor.assumeIsolated {
                guard let self, self.window == nil,
                      let scene = notification.object as? UIWindowScene else { return }
                self.attach(to: scene)
            }
        }
    }

    private static func activeScene() -> UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
    }

    private func attach(to scene: UIWindowScene) {
        if let activationObserver {
            NotificationCenter.default.removeObserver(activationObserver)
            self.activationObserver = nil
        }

        let window = PassthroughWindow(windowScene: scene)
        window.windowLevel = .alert + 1
        window.rootViewController = UIViewController()
        window.rootViewController?.view.backgroundColor = .clear

        if let root = window.rootViewController?.view {
            root.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                label.leadingAnchor.constraint(equalTo: root.safeAreaLayoutGuide.leadingAnchor, constant: 8),
                label.bottomAnchor.constraint(equalTo: root.safeAreaLayoutGuide.bottomAnchor, constant: -8),
                label.trailingAnchor.constraint(lessThanOrEqualTo: root.trailingAnchor, constant: -8),
            ])
        }

        window.isHidden = false
        self.window = window

        refresh()
        let timer = Timer(timeInterval: Self.refreshInterval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh() }
        }
        RunLoop.main.add(timer, forMode: .default)
        self.timer = timer
    }

    private func refresh() {
        let report = tracer.report()
        let scroll = report[.scrollHitchRatio]
        let hitch = report[.scrollHitch]
        let wait = report[.imageVisibleWait]
        let load = report[.imageLoad]

        let memoryHits = load?.tallies["source=memory"] ?? 0
        let total = memoryHits + (load?.tallies["source=network"] ?? 0)
        let hitRate = total > 0 ? "\(memoryHits * 100 / total)%" : "-"

        label.text = [
            " scroll \(PerformanceReport.format(scroll?.last)) ms/s  p90 \(PerformanceReport.format(scroll?.p90)) ",
            " hitches \(hitch?.count ?? 0)  worst \(PerformanceReport.format(hitch?.max)) ms ",
            " img wait p50 \(PerformanceReport.format(wait?.p50))  p90 \(PerformanceReport.format(wait?.p90)) ms ",
            " cache hit \(hitRate) ",
        ].joined(separator: "\n")
        label.accessibilityValue = report.jsonString()

        let severity = scroll?.last.map { scroll?.budget.severity(of: $0) ?? .ok } ?? .ok
        label.backgroundColor = severity.color.withAlphaComponent(0.8)
    }
}

/// Lets every touch through to the app's own window underneath.
private final class PassthroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? { nil }
}

private extension PerformanceSeverity {
    var color: UIColor {
        switch self {
        case .ok: return .systemGreen
        case .warning: return .systemOrange
        case .error: return .systemRed
        }
    }
}
