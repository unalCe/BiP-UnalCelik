import ImageCacheKit
import SwiftUI

public struct CachedImage: View {
    private let url: URL?
    private let maxPointSize: CGFloat
    private let loader: any ImageLoaderInterface

    @Environment(\.displayScale) private var displayScale
    @State private var uiImage: UIImage?

    public init(url: URL?, maxPointSize: CGFloat, loader: any ImageLoaderInterface) {
        self.url = url
        self.maxPointSize = maxPointSize
        self.loader = loader
    }

    public var body: some View {
        Group {
            if let uiImage {
                Image(uiImage: uiImage).resizable().scaledToFill()
            } else {
                Rectangle().fill(.quaternary)
            }
        }
        .task(id: url) {
            guard let url else { return }
            let request = ImageRequest(url: url, pointSize: maxPointSize, scale: displayScale)
            guard let loaded = try? await loader.image(for: request) else { return }
            guard !Task.isCancelled else { return }
            uiImage = loaded
        }
    }
}
