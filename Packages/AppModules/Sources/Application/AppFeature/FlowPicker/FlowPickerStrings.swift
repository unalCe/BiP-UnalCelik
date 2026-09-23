import CommonKit
import Foundation

extension AppStrings {
    enum FlowPicker {
        static var title: String {
            String(localized: "flowPicker.title", bundle: .module,
                   comment: "Navigation title of the sheet that switches the running architecture")
        }

        static func current(_ flow: String) -> String {
            String(localized: "flowPicker.current \(flow)", bundle: .module,
                   comment: "Names the architecture the app is running now. %@ is its name, e.g. MVVM-C · UIKit")
        }

        static func restart(_ flow: String) -> String {
            String(localized: "flowPicker.restart \(flow)", bundle: .module,
                   comment: "Button that restarts the app on the chosen architecture. %@ is its name, e.g. VIPER · UIKit")
        }

        static var viperLockReason: String {
            String(localized: "flowPicker.viperLockReason", bundle: .module,
                   comment: "Explains why the UIKit/SwiftUI choice is disabled while VIPER is selected")
        }

        static var infoButton: String {
            String(localized: "flowPicker.infoButton", bundle: .module,
                   comment: "Accessibility label of the navigation bar button that opens the architecture switcher")
        }
    }
}
