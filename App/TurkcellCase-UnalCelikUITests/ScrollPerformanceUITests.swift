import XCTest

/// Two kinds of scroll-performance check, because they answer different
/// questions:
///
/// - `testScrolling_staysWithinHitchBudget` is a hard gate. It reads the app's
///   own hitch measurement off the performance HUD and fails when a typical
///   scroll session breaks the error budget. Absolute, no baseline needed.
///   `testHitchBudget_catchesInjectedStalls` is its canary: it stalls the
///   main thread on purpose and requires the gate to trip, so a green gate
///   can't mean "measuring nothing".
///
/// - `testScrolling_signpostMetrics` is Apple's `XCTOSSignpostMetric`, driven
///   by UIKit's own scroll signposts. It fails only against a baseline you set
///   in Xcode (Test navigator ▸ result ▸ Set Baseline), per device, so it
///   catches relative regressions rather than absolute ones.
///
/// Both hit the live API, and hitch numbers only mean much on a device; the
/// simulator renders on the Mac's GPU. Treat simulator results as a smoke test.
final class ScrollPerformanceUITests: XCTestCase {
    /// Mirrors `PerformanceBudget.default(for: .scrollHitchRatio).error`.
    /// Apple's scale: under 5 ms/s good, 5–10 noticeable, over 10 critical.
    private static let hitchRatioErrorBudget = 10.0

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testScrolling_staysWithinHitchBudget() throws {
        let app = launchIntoProductList(arguments: ["-perfHUD", "YES"])
        let scroll = try scrollAndReadHitchRatio(in: app)

        // p90 of sessions, not max: one cold-cache session should warn in the
        // console, not fail the build.
        let p90 = try XCTUnwrap(scroll.p90)
        XCTAssertLessThanOrEqual(
            p90, Self.hitchRatioErrorBudget,
            """
            Scroll hitch ratio p90 \(p90) ms/s is over the \(Self.hitchRatioErrorBudget) ms/s budget \
            (\(scroll.count) sessions, worst \(scroll.max ?? 0) ms/s). See the attached report.
            """
        )
    }

    @MainActor
    func testHitchBudget_catchesInjectedStalls() throws {
        let app = launchIntoProductList(arguments: ["-perfHUD", "YES", "-perfInjectStallMs", "60"])
        let scroll = try scrollAndReadHitchRatio(in: app)

        let p90 = try XCTUnwrap(scroll.p90)
        XCTAssertGreaterThan(
            p90, Self.hitchRatioErrorBudget,
            "A 60 ms stall every 10th frame must break the budget. If it doesn't, the hitch detection is blind."
        )
        XCTAssertGreaterThan(scroll.errors, 0, "budget breaches should have been counted and logged")
    }

    @MainActor
    func testScrolling_signpostMetrics() throws {
        let app = launchIntoProductList(arguments: [])
        let grid = app.collectionViews.firstMatch

        let options = XCTMeasureOptions()
        options.invocationOptions = [.manuallyStop]

        measure(metrics: [XCTOSSignpostMetric.scrollDecelerationMetric,
                          XCTOSSignpostMetric.scrollDraggingMetric],
                options: options) {
            grid.swipeUp(velocity: .fast)
            stopMeasuring()
            grid.swipeDown(velocity: .fast)
        }
    }

    // MARK: - Helpers

    @MainActor
    private func scrollAndReadHitchRatio(in app: XCUIApplication) throws -> Report.Entry {
        let grid = app.collectionViews.firstMatch
        for _ in 0..<4 { grid.swipeUp(velocity: .fast) }
        for _ in 0..<4 { grid.swipeDown(velocity: .fast) }

        let report = try settledReport(in: app)
        return try XCTUnwrap(report.entries["scroll.hitchRatio"], "no scroll session was recorded")
    }

    @MainActor
    private func launchIntoProductList(arguments: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += arguments
        app.launch()

        app.buttons["Open MVVM-C · UIKit"].tap()
        XCTAssertTrue(app.collectionViews.firstMatch.cells.firstMatch.waitForExistence(timeout: 15),
                      "the product list never loaded")
        return app
    }

    /// The HUD refreshes on a timer that pauses while scrolling, so wait for
    /// the session count to stop changing before reading it.
    @MainActor
    private func settledReport(in app: XCUIApplication) throws -> Report {
        let hud = app.staticTexts["performance.hud"]
        XCTAssertTrue(hud.waitForExistence(timeout: 5), "the performance HUD is missing")

        var previous: Report?
        for _ in 0..<20 {
            let report = try Report(hud.value as? String ?? "")
            if let previous, previous == report, report.entries["scroll.hitchRatio"] != nil {
                attach(report)
                return report
            }
            previous = report
            Thread.sleep(forTimeInterval: 0.6)
        }
        let report = try Report(hud.value as? String ?? "")
        attach(report)
        return report
    }

    private func attach(_ report: Report) {
        let attachment = XCTAttachment(string: report.json)
        attachment.name = "Performance report"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

/// Mirrors the parts of `PerformanceReport` the assertions need. The UI test
/// bundle runs out of process and cannot link the app's packages.
private struct Report: Decodable, Equatable {
    struct Entry: Decodable, Equatable {
        let count: Int
        let p50: Double?
        let p90: Double?
        let max: Double?
        let warnings: Int
        let errors: Int
    }

    let entries: [String: Entry]
    private(set) var json = ""

    private enum CodingKeys: String, CodingKey { case entries }

    init(_ json: String) throws {
        self = try JSONDecoder().decode(Report.self, from: Data(json.utf8))
        self.json = json
    }
}
