import CommonKit
import ImageCacheKit
import UIKit

@MainActor
public final class CachedImageView: UIImageView {
    private static let failurePlaceholder =
        UIImage(systemName: ImagePlaceholder.failureSymbol) ?? UIImage()

    private let loader: ImageLoaderInterface

    private var loadTask: Task<Void, Never>?
    private var pendingURL: URL?
    private var currentRequest: ImageRequest?
    private var wantsShimmer = false

    // MARK: - Subviews

    private let shimmer = ShimmerSweep()

    // MARK: - Lifecycle

    public init(loader: ImageLoaderInterface) {
        self.loader = loader
        super.init(frame: .zero)
        contentMode = .scaleAspectFill
        clipsToBounds = true
        backgroundColor = Skeleton.fill
        shimmer.attach(to: layer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public override func layoutSubviews() {
        super.layoutSubviews()

        shimmer.layout(
            in: bounds,
            clippedTo: UIBezierPath(
                roundedRect: bounds, cornerRadius: layer.cornerRadius
            ).cgPath
        )
        if wantsShimmer, !shimmer.isRunning {
            shimmer.start()
        }

        loadIfNeeded()
    }

    // MARK: - Public Funcs

    var isSweeping: Bool { shimmer.isRunning }

    var isShowingFailure: Bool { image === Self.failurePlaceholder }

    public func setImage(from url: URL?,
                         placeholder: UIImage? = nil) {
        cancel()
        contentMode = .scaleAspectFill
        image = placeholder
        pendingURL = url
        wantsShimmer = url != nil && placeholder == nil
        setNeedsLayout()
    }

    public func cancel() {
        loadTask?.cancel()
        loadTask = nil
        pendingURL = nil
        currentRequest = nil
        wantsShimmer = false
        shimmer.stop()
        isAccessibilityElement = false
        accessibilityLabel = nil
    }

    // MARK: - Private Funcs

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
            do {
                let loaded = try await loader.image(for: request)
                guard self.currentRequest == request else { return }
                self.show(loaded)
            } catch {
                // a cancelled load is a resize or a reused cell, not a failure —
                // the pass that superseded it is already loading the right thing
                guard !(error is CancellationError), !Task.isCancelled else { return }
                guard self.currentRequest == request else { return }
                self.showFailure()
            }
        }
    }

    private func show(_ loaded: UIImage) {
        contentMode = .scaleAspectFill
        image = loaded
        stopSweeping()
    }

    /// `currentRequest` deliberately keeps the request that failed: the
    /// placeholder lays out again, and clearing it there would retry on every
    /// pass. A new size or a new `setImage` still gets a fresh attempt.
    private func showFailure() {
        contentMode = .center
        tintColor = .secondaryLabel
        image = Self.failurePlaceholder
        isAccessibilityElement = true
        accessibilityLabel = AppStrings.Common.imageUnavailable
        stopSweeping()
    }

    private func stopSweeping() {
        wantsShimmer = false
        shimmer.stop()
    }
}
