import UIKit

/// MVVM-C entry point for the detail. `onFinish` is an intent; dismissing the
/// screen is the coordinator's job.
@MainActor
public protocol ProductDetailScreenFactory {
    func makeScreen(productID: String, onFinish: @escaping () -> Void) -> UIViewController
}
