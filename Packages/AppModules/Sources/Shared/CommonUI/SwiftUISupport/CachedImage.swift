import SwiftUI
import ImageCacheKit

public struct CachedImage: View {
    private let url: URL?
    private let loader: any ImageLoaderInterface

    @State private var uiImage: UIImage?

    public init(url: URL?, loader: any ImageLoaderInterface) {
        self.url = url
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
            guard let data = try? await loader.data(for: url) else { return }
            guard !Task.isCancelled else { return }
            uiImage = UIImage(data: data)
        }
    }
}
