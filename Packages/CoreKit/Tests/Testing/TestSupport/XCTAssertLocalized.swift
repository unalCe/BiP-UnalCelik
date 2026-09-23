import XCTest

/// `String(localized:bundle:)` returns the key itself when the catalog is
/// missing from the bundle. Keys are semantic (`productList.empty.title`), so
/// anything shaped like one never made it through the catalog.
public func XCTAssertLocalized(
    _ strings: [String],
    file: StaticString = #filePath,
    line: UInt = #line
) {
    for string in strings {
        XCTAssertNil(
            string.range(of: #"^[a-z]+[A-Za-z]*\.[A-Za-z.]+"#, options: .regularExpression),
            "\"\(string)\" looks like an unresolved key",
            file: file,
            line: line
        )
    }
}
