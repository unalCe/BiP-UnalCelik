import Foundation

/// Every user-facing string, resolved from this module's catalog. Views take
/// the resolved `String`: a SwiftUI literal would look its key up in the main
/// bundle, where this catalog is not.
public enum AppStrings {
    public enum Common {
        public static var tryAgain: String {
            String(localized: "common.tryAgain", bundle: .module,
                   comment: "Button that repeats a request that failed or came back empty")
        }

        public static var imageUnavailable: String {
            String(localized: "common.imageUnavailable", bundle: .module,
                   comment: "VoiceOver label for a product image that failed to load")
        }
    }

    public enum Error {
        public static var notFoundTitle: String {
            String(localized: "error.notFound.title", bundle: .module,
                   comment: "Error title: the requested product does not exist")
        }

        public static var notFoundMessage: String {
            String(localized: "error.notFound.message", bundle: .module,
                   comment: "Error message under the product-not-found title")
        }

        public static var offlineTitle: String {
            String(localized: "error.offline.title", bundle: .module,
                   comment: "Error title: the device has no network connection")
        }

        public static var offlineMessage: String {
            String(localized: "error.offline.message", bundle: .module,
                   comment: "Error message under the offline title")
        }

        public static var invalidDataTitle: String {
            String(localized: "error.invalidData.title", bundle: .module,
                   comment: "Error title: the server answered with data the app cannot read")
        }

        public static var invalidDataMessage: String {
            String(localized: "error.invalidData.message", bundle: .module,
                   comment: "Error message under the unreadable-response title")
        }

        public static var genericTitle: String {
            String(localized: "error.generic.title", bundle: .module,
                   comment: "Error title for any failure without a more specific explanation")
        }

        public static var genericMessage: String {
            String(localized: "error.generic.message", bundle: .module,
                   comment: "Error message under the generic error title")
        }
    }

    public enum ProductList {
        public static var title: String {
            String(localized: "productList.title", bundle: .module,
                   comment: "Navigation title of the product list")
        }

        public static var emptyTitle: String {
            String(localized: "productList.empty.title", bundle: .module,
                   comment: "Shown instead of the list when the server returns no products")
        }
    }

    public enum ProductDetail {
        public static var descriptionUnavailable: String {
            String(localized: "productDetail.descriptionUnavailable", bundle: .module,
                   comment: "Shown in place of a product description the server did not send")
        }

        public static var emptyTitle: String {
            String(localized: "productDetail.empty.title", bundle: .module,
                   comment: "Shown instead of the detail screen when there is no product to show")
        }
    }

    public enum FlowPicker {
        public static var title: String {
            String(localized: "flowPicker.title", bundle: .module,
                   comment: "Navigation title of the screen that picks an architecture to open")
        }

        /// `flow` is a product name such as "MVVM-C · UIKit" and is not translated.
        public static func open(_ flow: String) -> String {
            String(localized: "flowPicker.open \(flow)", bundle: .module,
                   comment: "Button that opens the chosen architecture. %@ is its name, e.g. MVVM-C · UIKit")
        }

        public static var viperLockReason: String {
            String(localized: "flowPicker.viperLockReason", bundle: .module,
                   comment: "Explains why the UIKit/SwiftUI choice is disabled while VIPER is selected")
        }
    }
}
