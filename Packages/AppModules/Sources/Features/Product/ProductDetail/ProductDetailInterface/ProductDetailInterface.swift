import UIKit

@MainActor
public protocol ProductDetailInterface {
    func createModule(
        navigationController: UINavigationController?,
        productID: String
    ) -> UIViewController
}
