import CommonKit
import Foundation

extension AppStrings {
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
}
