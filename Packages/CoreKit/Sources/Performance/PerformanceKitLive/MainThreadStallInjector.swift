import UIKit

/// Blocks the main thread for a fixed time every few frames. Exists to prove
/// the hitch detection end to end — that the monitor sees it, the console
/// warns, and the UI test gate fails — rather than trusting a green run that
/// might be measuring nothing. DEBUG builds only.
@MainActor
public final class MainThreadStallInjector {
    private static var running: MainThreadStallInjector?

    private let stall: TimeInterval
    private let everyFrames: Int
    private var frame = 0
    private var displayLink: CADisplayLink?

    private init(milliseconds: Int, everyFrames: Int) {
        self.stall = TimeInterval(milliseconds) / 1_000
        self.everyFrames = everyFrames
    }

    public static func start(milliseconds: Int, everyFrames: Int = 10) {
        #if DEBUG
        guard running == nil, milliseconds > 0 else { return }
        let injector = MainThreadStallInjector(milliseconds: milliseconds, everyFrames: everyFrames)
        let link = CADisplayLink(target: injector, selector: #selector(tick))
        link.add(to: .main, forMode: .common)
        injector.displayLink = link
        running = injector
        #endif
    }

    @objc private func tick() {
        frame += 1
        guard frame % everyFrames == 0 else { return }
        Thread.sleep(forTimeInterval: stall)
    }
}
