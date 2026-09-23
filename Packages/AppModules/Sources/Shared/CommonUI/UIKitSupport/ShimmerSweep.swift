import UIKit

/// A highlight that sweeps across a host layer, clipped to a path. The gradient
/// moves inside a container whose mask stays put, so the highlight is confined
/// to the placeholder shapes while travelling across them.
@MainActor
public final class ShimmerSweep {
    private enum Key { static let sweep = "shimmer.sweep" }

    private let container = CALayer()
    private let mask = CAShapeLayer()
    private let gradient: CAGradientLayer = {
        let layer = CAGradientLayer()
        layer.startPoint = CGPoint(x: 0, y: 0.5)
        layer.endPoint = CGPoint(x: 1, y: 0.5)
        layer.colors = [
            UIColor.white.withAlphaComponent(0).cgColor,
            UIColor.white.withAlphaComponent(Skeleton.highlightOpacity).cgColor,
            UIColor.white.withAlphaComponent(0).cgColor,
        ]
        return layer
    }()

    public init() {
        container.mask = mask
        container.addSublayer(gradient)
    }

    public func attach(to host: CALayer) {
        host.addSublayer(container)
    }

    public func layout(in bounds: CGRect, clippedTo path: CGPath) {
        container.frame = bounds
        mask.frame = bounds
        mask.path = path

        let band = bounds.width * Skeleton.sweepBandWidth
        gradient.frame = CGRect(x: -band, y: 0, width: band, height: bounds.height)
    }

    public var isRunning: Bool { gradient.animation(forKey: Key.sweep) != nil }

    public func start() {
        stop()
        let band = gradient.bounds.width
        guard band > 0, !UIAccessibility.isReduceMotionEnabled else { return }

        let sweep = CABasicAnimation(keyPath: "position.x")
        sweep.fromValue = -band / 2
        sweep.toValue = container.bounds.width + band / 2
        sweep.duration = Skeleton.sweepDuration
        sweep.repeatCount = .infinity
        sweep.timingFunction = CAMediaTimingFunction(name: .linear)
        gradient.add(sweep, forKey: Key.sweep)
    }

    public func stop() {
        gradient.removeAnimation(forKey: Key.sweep)
    }
}
