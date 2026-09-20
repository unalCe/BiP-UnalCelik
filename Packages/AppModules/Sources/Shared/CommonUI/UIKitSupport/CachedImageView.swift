import ImageCacheKit
import UIKit

/// Measures itself, so callers never do pixel arithmetic. The request is issued
/// from `layoutSubviews`, because bounds are zero until the cell is laid out.
@MainActor
public final class CachedImageView: UIImageView {
    private var loadTask: Task<Void, Never>?
    private var pendingURL: URL?
    private var currentRequest: ImageRequest?
    private let loader: any ImageLoaderInterface

    public init(loader: any ImageLoaderInterface) {
        self.loader = loader
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
        setNeedsLayout()
    }

    public func cancel() {
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

        let scale = traitCollection.displayScale > 0 ? traitCollection.displayScale : 3
        let pixelSize = Int(ceil(max(bounds.width, bounds.height) * scale))
        let request = ImageRequest(url: url, maxPixelSize: pixelSize, scale: scale)

        // Also what stops an infinite layout pass: assigning `image` can change
        // `intrinsicContentSize`, which lays out again.
        guard request != currentRequest else { return }

        loadTask?.cancel()
        currentRequest = request

        loadTask = Task { [loader] in
            guard let loaded = try? await loader.image(for: request) else { return }
            guard self.currentRequest == request else { return }
            self.image = loaded
        }
    }
}
