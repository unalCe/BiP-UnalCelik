import UIKit
import ImageCacheKit

/// Holds its load task so `prepareForReuse` can cancel it — otherwise a fast
/// scroll lands the wrong image in a recycled cell.
@MainActor
public final class CachedImageView: UIImageView {
    private var loadTask: Task<Void, Never>?
    private var currentURL: URL?
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
        currentURL = url
        guard let url else { return }

        loadTask = Task { [loader] in
            guard let data = try? await loader.data(for: url) else { return }
            // TODO: decode + downsample off the main thread
            guard !Task.isCancelled, self.currentURL == url else { return }
            self.image = UIImage(data: data)
        }
    }

    public func cancel() {
        loadTask?.cancel()
        loadTask = nil
        currentURL = nil
    }
}
