import Darwin
import ImageCacheKit
import ImageIO
import PerformanceKit
import UIKit

/// Traces only the decode call, as wall time (`image.decode`) and this
/// thread's CPU time (`image.decodeCPU`). On device ImageIO hands JPEGs to
/// the hardware decoder, so a slow decode can be a thread blocked waiting its
/// turn rather than one burning CPU; the pair tells the two apart.
struct CGImageDownsampler: ImageDownsampling {
    private let tracer: any PerformanceTracing

    init(tracer: any PerformanceTracing = NoopPerformanceTracer()) {
        self.tracer = tracer
    }

    func downsample(_ data: Data, maxPixelSize: Int, scale: CGFloat) async throws -> UIImage {
        try Task.checkCancellation()

        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithData(data as CFData, sourceOptions) else {
            throw ImageLoadingError.invalidData
        }

        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceShouldCacheImmediately: true,
        ] as CFDictionary

        // Synchronous from here to the end, so the thread cannot change and
        // its CPU clock is a fair measure of this call alone.
        let interval = tracer.begin(.imageDecode)
        let cpuStart = clock_gettime_nsec_np(CLOCK_THREAD_CPUTIME_ID)
        let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options)
        let cpuMilliseconds = Double(clock_gettime_nsec_np(CLOCK_THREAD_CPUTIME_ID) - cpuStart) / 1_000_000

        guard let cgImage = thumbnail else {
            tracer.end(interval, outcome: .failed)
            throw ImageLoadingError.downsamplingFailed
        }
        tracer.end(interval)
        tracer.record(.imageDecodeCPU, value: cpuMilliseconds)

        return UIImage(cgImage: cgImage, scale: scale, orientation: .up)
    }
}
