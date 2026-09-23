import XCTest

/// `XCTAssertThrowsError` for `async` expressions, which XCTest does not ship.
/// Hands the error to `errorHandler` so the caller can inspect it.
public func XCTAssertThrowsErrorAsync<T>(
    _ expression: @autoclosure () async throws -> T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line,
    _ errorHandler: (Error) -> Void = { _ in }
) async {
    do {
        _ = try await expression()
        XCTFail(failureMessage("expected an error", message()), file: file, line: line)
    } catch {
        errorHandler(error)
    }
}

/// Fails unless the expression throws exactly `expected`. Covers the common
/// `do { …; XCTFail } catch let error as E { XCTAssertEqual } catch { XCTFail }` shape.
public func XCTAssertThrowsErrorAsync<T, E: Error & Equatable>(
    _ expression: @autoclosure () async throws -> T,
    equals expected: E,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    await XCTAssertThrowsErrorAsync(try await expression(), message(), file: file, line: line) { error in
        guard let error = error as? E else {
            return XCTFail(
                failureMessage("expected \(E.self).\(expected), got \(error)", message()),
                file: file, line: line
            )
        }
        XCTAssertEqual(error, expected, message(), file: file, line: line)
    }
}

private func failureMessage(_ reason: String, _ message: String) -> String {
    message.isEmpty ? reason : "\(reason) — \(message)"
}
