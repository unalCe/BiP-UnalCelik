import PerformanceKit
import XCTest

final class HitchAccumulatorTests: XCTestCase {
    private let frame: TimeInterval = 1.0 / 60

    func test_framesOnTime_recordNoHitches() {
        var sut = HitchAccumulator()
        feed(&sut, presentedAt: (0...60).map { Double($0) * frame })

        XCTAssertEqual(sut.frameCount, 60)
        XCTAssertEqual(sut.hitchCount, 0)
        XCTAssertEqual(sut.hitchRatio, 0)
        XCTAssertEqual(sut.duration, 1, accuracy: 0.0001)
    }

    func test_aFrameThreeIntervalsLate_countsTwoIntervalsOfHitch() {
        var sut = HitchAccumulator()
        // Frame 3 arrives at slot 5: the main thread held two frames.
        let slots = [0, 1, 2, 5, 6, 7]
        feed(&sut, presentedAt: slots.map { Double($0) * frame })

        XCTAssertEqual(sut.hitchCount, 1)
        XCTAssertEqual(sut.hitchTime, 2 * frame, accuracy: 0.0001)
        XCTAssertEqual(sut.worstHitch, 2 * frame, accuracy: 0.0001)
    }

    func test_hitchRatio_isHitchMillisecondsPerSecond() {
        var sut = HitchAccumulator()
        // One 50 ms hitch across one second of scrolling.
        var times = (0...30).map { Double($0) * frame }
        let resume = times.last! + frame + 0.05
        times += (0..<29).map { resume + Double($0) * frame }
        feed(&sut, presentedAt: times)

        XCTAssertEqual(sut.hitchTime * 1_000, 50, accuracy: 0.1)
        XCTAssertEqual(sut.hitchRatio, 50 / sut.duration, accuracy: 0.1)
    }

    func test_subMillisecondJitter_isNotAHitch() {
        var sut = HitchAccumulator()
        sut.addFrame(timestamp: 0, targetTimestamp: frame)
        let lateness = sut.addFrame(timestamp: frame + 0.0005, targetTimestamp: 2 * frame)

        XCTAssertNil(lateness)
        XCTAssertEqual(sut.hitchCount, 0)
    }

    func test_budgetSeverity() {
        let budget = PerformanceBudget(warning: 5, error: 10)

        XCTAssertEqual(budget.severity(of: 5), .ok)
        XCTAssertEqual(budget.severity(of: 7), .warning)
        XCTAssertEqual(budget.severity(of: 10.1), .error)
    }

    /// A display link reports each frame with the next one's due time.
    private func feed(_ sut: inout HitchAccumulator, presentedAt times: [TimeInterval]) {
        for time in times {
            sut.addFrame(timestamp: time, targetTimestamp: time + frame)
        }
    }
}
