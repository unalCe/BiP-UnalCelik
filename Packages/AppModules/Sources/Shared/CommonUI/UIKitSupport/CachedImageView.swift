import ImageCacheKit
import PerformanceKit
import UIKit

@MainActor
public final class CachedImageView: UIImageView {
    private var loadTask: Task<Void, Never>?
    private var pendingURL: URL?
    private var currentRequest: ImageRequest?
    private let loader: any ImageLoaderInterface
    private let tracer: any PerformanceTracing
    /// Open from `setImage` until the image lands: how long the placeholder
    /// was on screen. A reuse before that ends it as `.cancelled`.
    private var visibleWait: PerformanceInterval?

    public init(loader: any ImageLoaderInterface,
                tracer: any PerformanceTracing = NoopPerformanceTracer()) {
        self.loader = loader
        self.tracer = tracer
        super.init(frame: .zero)
        contentMode = .scaleAspectFill
        clipsToBounds = true
        backgroundColor = .secondarySystemFill
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public func setImage(from url: URL?, placeholder: UIImage? = nil) {
        cancel()
        image = placeholder
        pendingURL = url
        if url != nil { visibleWait = tracer.begin(.imageVisibleWait) }
        setNeedsLayout()
    }

    public func cancel() {
        endVisibleWait(.cancelled)
        loadTask?.cancel()
        loadTask = nil
        pendingURL = nil
        currentRequest = nil
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        loadIfNeeded()
    }

    private func loadIfNeeded() {
        guard let url = pendingURL, bounds.width > 0, bounds.height > 0 else { return }

        let request = ImageRequest(
            url: url,
            pointSize: max(bounds.width, bounds.height),
            scale: traitCollection.displayScale
        )

        // also stops an infinite layout pass: setting `image` changes
        // `intrinsicContentSize`, which lays out again
        guard request != currentRequest else { return }

        loadTask?.cancel()
        currentRequest = request

        loadTask = Task { [loader] in
            let loaded = try? await loader.image(for: request)
            guard self.currentRequest == request else { return }
            guard let loaded else { return self.endVisibleWait(.failed) }
            self.image = loaded
            self.endVisibleWait(.completed)
        }
    }

    private func endVisibleWait(_ outcome: PerformanceOutcome) {
        guard let visibleWait else { return }
        self.visibleWait = nil
        tracer.end(visibleWait, outcome: outcome)
    }
}
