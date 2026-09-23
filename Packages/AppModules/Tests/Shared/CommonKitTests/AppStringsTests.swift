import TestSupport
import XCTest

@testable import CommonKit

/// An unresolved key comes back as the key itself, so these fail if the
/// catalog is missing from the module's bundle rather than quietly showing
/// `common.tryAgain` on screen.
final class AppStringsTests: XCTestCase {
    func test_resolvesFromTheCatalog() {
        XCTAssertEqual(AppStrings.Common.tryAgain, "Try again")
        XCTAssertEqual(AppStrings.Error.offlineTitle, "You're offline")
    }

    func test_noStringFallsBackToItsKey() {
        XCTAssertLocalized([
            AppStrings.Common.tryAgain, AppStrings.Common.imageUnavailable,
            AppStrings.Error.offlineTitle, AppStrings.Error.offlineMessage,
            AppStrings.Error.invalidDataTitle, AppStrings.Error.invalidDataMessage,
            AppStrings.Error.genericTitle, AppStrings.Error.genericMessage,
        ])
    }
}
