import ImageCacheKit
import UIKit

final class NSCacheImageCache: DecodedImageCaching, @unchecked Sendable {
    private final class Key: NSObject {
        let request: ImageRequest

        init(_ request: ImageRequest) { self.request = request }

        override var hash: Int { request.hashValue }

        override func isEqual(_ object: Any?) -> Bool {
            (object as? Key)?.request == request
        }
    }

    private let storage = NSCache<Key, UIImage>()
    private var memoryWarningObserver: (any NSObjectProtocol)?

    init(totalCostLimit: Int = 64 * 1024 * 1024, countLimit: Int = 100) {
        storage.totalCostLimit = totalCostLimit
        storage.countLimit = countLimit

        memoryWarningObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.removeAll()
        }
    }

    deinit {
        if let memoryWarningObserver {
            NotificationCenter.default.removeObserver(memoryWarningObserver)
        }
    }

    func image(for request: ImageRequest) -> UIImage? {
        storage.object(forKey: Key(request))
    }

    func insert(_ image: UIImage, for request: ImageRequest) {
        storage.setObject(image, forKey: Key(request), cost: image.memoryCost)
    }

    func removeAll() {
        storage.removeAllObjects()
    }
}

private extension UIImage {
    var memoryCost: Int {
        guard let cgImage else { return 0 }
        return cgImage.bytesPerRow * cgImage.height
    }
}
