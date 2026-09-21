import PerformanceKitMocks
import UIKit
import XCTest
@testable import ImageCacheKitLive

final class CGImageDownsamplerTests: XCTestCase {
    func test_decode_tracesWallAndCPUTime() async throws {
        let tracer = RecordingPerformanceTracer()
        let sut = CGImageDownsampler(tracer: tracer)

        let image = try await sut.downsample(Self.jpeg(side: 800), maxPixelSize: 128, scale: 1)

        XCTAssertLessThanOrEqual(max(image.size.width, image.size.height), 128)
        let wall = try XCTUnwrap(tracer.samples(for: .imageDecode).first)
        let cpu = try XCTUnwrap(tracer.samples(for: .imageDecodeCPU).first)
        XCTAssertEqual(wall.outcome, .completed)
        XCTAssertGreaterThan(cpu.value, 0)
        // A thread cannot spend more CPU than wall time in one synchronous call.
        XCTAssertLessThanOrEqual(cpu.value, wall.value + 1)
        XCTAssertTrue(tracer.openIntervals.isEmpty)
    }

    /// ImageIO accepts garbage as a source and only fails at the thumbnail,
    /// so the decode is traced, as failed, and no CPU sample skews the stats.
    func test_undecodableData_tracesAFailedDecode() async {
        let tracer = RecordingPerformanceTracer()
        let sut = CGImageDownsampler(tracer: tracer)

        _ = try? await sut.downsample(Data("not an image".utf8), maxPixelSize: 128, scale: 1)

        XCTAssertEqual(tracer.samples(for: .imageDecode).map(\.outcome), [.failed])
        XCTAssertTrue(tracer.samples(for: .imageDecodeCPU).isEmpty)
        XCTAssertTrue(tracer.openIntervals.isEmpty)
    }

    private static func jpeg(side: CGFloat) -> Data {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: side, height: side))
        return renderer.jpegData(withCompressionQuality: 0.8) { context in
            UIColor.systemOrange.setFill()
            context.fill(CGRect(x: 0, y: 0, width: side, height: side))
        }
    }
}
