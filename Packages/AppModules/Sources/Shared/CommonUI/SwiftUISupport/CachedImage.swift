import ImageCacheKit
import SwiftUI

/// Measures itself and asks for the pixels it can show, mirroring
/// `CachedImageView`. Fills and centres like `.scaleAspectFill` + `clipsToBounds`.
public struct CachedImage: View {
    private let url: URL?
    private let loader: any ImageLoaderInterface

    @Environment(\.displayScale) private var displayScale
    @State private var uiImage: UIImage?

    public init(url: URL?, loader: any ImageLoaderInterface) {
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
        if let uiImage {
            Image(uiImage: uiImage).resizable().scaledToFill()
        } else {
            SkeletonBox(cornerRadius: 0)
        }
    }

    private func load(pointSize: CGFloat) async {
        guard let url, pointSize > 0 else { return }
        let request = ImageRequest(url: url, pointSize: pointSize, scale: displayScale)
        guard let loaded = try? await loader.image(for: request) else { return }
        guard !Task.isCancelled else { return }
        uiImage = loaded
    }

    private struct Request: Equatable {
        let url: URL?
        let side: CGFloat
    }
}
