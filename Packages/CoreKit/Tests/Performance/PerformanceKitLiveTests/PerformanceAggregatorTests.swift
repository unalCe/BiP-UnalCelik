import PerformanceKit
import XCTest
@testable import PerformanceKitLive

final class PerformanceAggregatorTests: XCTestCase {
    func test_percentiles_areNearestRank() {
        var sut = PerformanceAggregator(budgets: [:])
        for value in 1...10 {
            sut.add(.imageLoad, value: Double(value), outcome: .completed, attributes: [:])
        }

        let entry = sut.report()[.imageLoad]
        XCTAssertEqual(entry?.count, 10)
        XCTAssertEqual(entry?.p50, 5)
        XCTAssertEqual(entry?.p90, 9)
        XCTAssertEqual(entry?.max, 10)
        XCTAssertEqual(entry?.last, 10)
    }

    func test_cancelledSamples_areCountedButStayOutOfThePercentiles() {
        var sut = PerformanceAggregator(budgets: [:])
        sut.add(.imageVisibleWait, value: 10, outcome: .completed, attributes: [:])
        let severity = sut.add(.imageVisibleWait, value: 9_000, outcome: .cancelled, attributes: [:])

        let entry = sut.report()[.imageVisibleWait]
        XCTAssertEqual(severity, .ok)
        XCTAssertEqual(entry?.count, 1)
        XCTAssertEqual(entry?.max, 10)
        XCTAssertEqual(entry?.outcomes, ["completed": 1, "cancelled": 1])
    }

    func test_budgetBreaches_areClassifiedAndCounted() {
        var sut = PerformanceAggregator(budgets: [.scrollHitchRatio: PerformanceBudget(warning: 5, error: 10)])

        XCTAssertEqual(sut.add(.scrollHitchRatio, value: 3, outcome: .completed, attributes: [:]), .ok)
        XCTAssertEqual(sut.add(.scrollHitchRatio, value: 7, outcome: .completed, attributes: [:]), .warning)
        XCTAssertEqual(sut.add(.scrollHitchRatio, value: 20, outcome: .completed, attributes: [:]), .error)

        let entry = sut.report()[.scrollHitchRatio]
        XCTAssertEqual(entry?.warnings, 1)
        XCTAssertEqual(entry?.errors, 1)
    }

    func test_onlyTheSourceAttributeIsTallied() {
        var sut = PerformanceAggregator(budgets: [:])
        sut.add(.imageLoad, value: 1, outcome: .completed, attributes: ["source": "memory", "count": "3"])
        sut.add(.imageLoad, value: 1, outcome: .completed, attributes: ["source": "memory"])
        sut.add(.imageLoad, value: 1, outcome: .completed, attributes: ["source": "network"])

        XCTAssertEqual(sut.report()[.imageLoad]?.tallies, ["source=memory": 2, "source=network": 1])
    }

    func test_samples_areCapped() {
        var sut = PerformanceAggregator(budgets: [:])
        for value in 0..<(PerformanceAggregator.sampleLimit + 10) {
            sut.add(.imageDecode, value: Double(value), outcome: .completed, attributes: [:])
        }

        XCTAssertEqual(sut.report()[.imageDecode]?.count, PerformanceAggregator.sampleLimit)
    }

    func test_tracer_feedsItsReport() {
        let sut = PerformanceTracer(reportsOnBackground: false)
        let interval = sut.begin(.productsFetch)
        sut.end(interval)
        sut.record(.scrollHitchRatio, value: 4)

        let report = sut.report()
        XCTAssertEqual(report[.productsFetch]?.count, 1)
        XCTAssertEqual(report[.scrollHitchRatio]?.last, 4)
    }

    func test_report_roundTripsThroughJSON() throws {
        var sut = PerformanceAggregator(budgets: [:])
        sut.add(.imageLoad, value: 12, outcome: .completed, attributes: ["source": "network"])
        let report = sut.report()

        let decoded = try JSONDecoder().decode(PerformanceReport.self, from: Data(report.jsonString().utf8))
        XCTAssertEqual(decoded, report)
    }

    func test_hudImpliesTracing() {
        XCTAssertTrue(PerformanceConfiguration(isTracingEnabled: false, showsHUD: true).isTracingEnabled)
    }
}
