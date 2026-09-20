import ImageCacheKit
import SwiftUI

/// Takes its size explicitly: every call site already applies a fixed frame, so
/// the caller knows the answer and a `GeometryReader` would only add layout
/// quirks. The UIKit view measures itself instead.
public struct CachedImage: View {
    private let url: URL?
    private let maxPixelSize: Int
    private let loader: any ImageLoaderInterface

    @Environment(\.displayScale) private var displayScale
    @State private var uiImage: UIImage?

    public init(url: URL?, maxPixelSize: Int, loader: any ImageLoaderInterface) {
        self.url = url
        self.maxPixelSize = maxPixelSize
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
            let request = ImageRequest(
                url: url,
                maxPixelSize: Int(ceil(Double(maxPixelSize) * displayScale)),
                scale: displayScale
            )
            guard let loaded = try? await loader.image(for: request) else { return }
            guard !Task.isCancelled else { return }
            uiImage = loaded
        }
    }
}
