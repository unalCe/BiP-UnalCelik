import ImageCacheKit
import UIKit

@MainActor
public final class CachedImageView: UIImageView {
    private var loadTask: Task<Void, Never>?
    private var pendingURL: URL?
    private var currentRequest: ImageRequest?
    private let loader: any ImageLoaderInterface
    private let shimmer = ShimmerSweep()
    private var wantsShimmer = false

    public init(loader: any ImageLoaderInterface) {
        self.loader = loader
        super.init(frame: .zero)
        contentMode = .scaleAspectFill
        clipsToBounds = true
        backgroundColor = Skeleton.fill
        shimmer.attach(to: layer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    public func setImage(from url: URL?,
                         placeholder: UIImage? = nil) {
        cancel()
        image = placeholder
        pendingURL = url
        wantsShimmer = url != nil && placeholder == nil
        setNeedsLayout()
    }

    var isSweeping: Bool { shimmer.isRunning }

    public func cancel() {
        loadTask?.cancel()
        loadTask = nil
        pendingURL = nil
        currentRequest = nil
        wantsShimmer = false
        shimmer.stop()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()

        // the cell sets cornerRadius after init, so re-read it every pass
        shimmer.layout(
            in: bounds,
            clippedTo: UIBezierPath(
                roundedRect: bounds, cornerRadius: layer.cornerRadius
            ).cgPath
        )
        // started here, not in setImage: the band is sized from bounds, which
        // are still zero when the cell configures itself
        if wantsShimmer, !shimmer.isRunning {
            shimmer.start()
        }

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
            guard let loaded = try? await loader.image(for: request) else { return }
            guard self.currentRequest == request else { return }
            self.image = loaded
            self.wantsShimmer = false
            self.shimmer.stop()
        }
    }
}
