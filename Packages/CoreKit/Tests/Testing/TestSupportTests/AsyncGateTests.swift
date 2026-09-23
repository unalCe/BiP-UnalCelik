import TestSupport
import XCTest

/// Other suites synchronise on the gate, so a bug here would surface as a hang
/// or a flake somewhere far away.
final class AsyncGateTests: XCTestCase {
    private var gate: AsyncGate!

    override func setUp() {
        super.setUp()
        gate = AsyncGate()
    }

    override func tearDown() {
        gate.open()
        gate = nil
        super.tearDown()
    }

    func test_wait_suspendsUntilOpened() async {
        let gate = gate!
        let released = expectation(description: "released")
        released.isInverted = true

        let waiter = Task {
            await gate.wait()
            released.fulfill()
        }
        await fulfillment(of: [released], timeout: 0.1)

        gate.open()
        await waiter.value
    }

    func test_open_releasesEveryWaiter() async {
        let gate = gate!
        let first = Task { await gate.wait() }
        let second = Task { await gate.wait() }

        gate.open()

        await first.value
        await second.value
    }

    func test_openGate_doesNotSuspend() async {
        gate.open()

        await gate.wait()

        XCTAssertEqual(gate.waiterCount, 0)
    }

    func test_cancellingAWaiter_releasesItAlone() async {
        let gate = gate!
        let cancelled = Task { await gate.wait() }
        let other = Task { await gate.wait() }

        cancelled.cancel()
        await cancelled.value

        gate.open()
        await other.value
    }
}
