import CommonKit
import ImageCacheKit
import SwiftUI

/// Measures itself and asks for the pixels it can show, mirroring
/// `CachedImageView`. Fills and centres like `.scaleAspectFill` + `clipsToBounds`.
public struct CachedImage: View {
    private enum Phase {
        case loading
        case loaded(UIImage)
        case failed
    }

    private let url: URL?
    private let loader: ImageLoaderInterface

    @Environment(\.displayScale) private var displayScale
    @State private var phase: Phase = .loading
    @State private var requestedURL: URL?

    public init(url: URL?, loader: ImageLoaderInterface) {
        self.url = url
        self.loader = loader
    }

    public var body: some View {
        GeometryReader { proxy in
            let side = max(proxy.size.width, proxy.size.height)

            content
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
                .task(id: Request(url: url, side: side)) {
                    await load(pointSize: side)
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch phase {
        case .loading:
            SkeletonBox(cornerRadius: 0)
                .shimmering()
                .accessibilityHidden(true)
        case .loaded(let uiImage):
            Image(uiImage: uiImage).resizable().scaledToFill()
        case .failed:
            SkeletonBox(cornerRadius: 0)
                .overlay {
                    Image(systemName: ImagePlaceholder.failureSymbol)
                        .imageScale(.large)
                        .foregroundStyle(.secondary)
                }
                .accessibilityElement()
                .accessibilityLabel(AppStrings.Common.imageUnavailable)
        }
    }

    private func load(pointSize: CGFloat) async {
        // `.task(id:)` re-fires on every resize too; only a new URL is worth
        // clearing pixels that are already on screen for
        if requestedURL != url {
            requestedURL = url
            phase = .loading
        }
        guard let url, pointSize > 0 else {
            phase = .failed
            return
        }

        let request = ImageRequest(url: url, pointSize: pointSize, scale: displayScale)
        do {
            let loaded = try await loader.image(for: request)
            guard !Task.isCancelled else { return }
            phase = .loaded(loaded)
        } catch {
            // a cancelled load is a resize or a scrolled-away cell, not a
            // failure — flashing a broken image there is worse than waiting
            guard !(error is CancellationError), !Task.isCancelled else { return }
            phase = .failed
        }
    }

    private struct Request: Equatable {
        let url: URL?
        let side: CGFloat
    }
}
