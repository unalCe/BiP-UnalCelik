import Foundation

/// Views take the resolved `String`: a SwiftUI literal would look its key up in
/// the main bundle, where none of the catalogs are.
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
}
