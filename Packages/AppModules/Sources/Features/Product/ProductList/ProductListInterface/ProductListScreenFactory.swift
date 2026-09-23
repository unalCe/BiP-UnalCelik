import UIKit

/// MVVM-C entry point for the list. Unlike `ProductListInterface`, it never
/// sees a `UINavigationController`: selection leaves as an intent and the
/// coordinator decides where it goes.
@MainActor
public protocol ProductListScreenFactory {
    func makeScreen(onSelectProduct: @escaping (String) -> Void) -> UIViewController
}
