import UIKit

@MainActor
public protocol ProductListInterface {
    func createModule(navigationController: UINavigationController?) -> UIViewController
}
