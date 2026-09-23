import CommonKit
import Foundation

extension AppStrings {
    enum FlowPicker {
        static var title: String {
            String(localized: "flowPicker.title", bundle: .module,
                   comment: "Navigation title of the screen that picks an architecture to open")
        }

        /// `flow` is a product name such as "MVVM-C · UIKit" and is not translated.
        static func open(_ flow: String) -> String {
            String(localized: "flowPicker.open \(flow)", bundle: .module,
                   comment: "Button that opens the chosen architecture. %@ is its name, e.g. MVVM-C · UIKit")
        }

        static var viperLockReason: String {
            String(localized: "flowPicker.viperLockReason", bundle: .module,
                   comment: "Explains why the UIKit/SwiftUI choice is disabled while VIPER is selected")
        }
    }
}
