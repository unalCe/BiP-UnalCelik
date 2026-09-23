import AccessibilityKit

/// Every accessibility identifier the app exposes, in one place.
///
/// Views set them, UI-test page objects look them up. Both sides import this
/// module, so an identifier cannot be renamed on one side only.
public enum UIElements {
    public enum Shell: String, UIElement {
        case flowPickerButton = "shell.flowPickerButton"
    }

    public enum ProductList: String, UIElement {
        case collection = "productList.collection"
        /// Suffixed with the product id: `productList.cell.1`.
        case cell = "productList.cell"
        case skeleton = "productList.skeleton"
    }

    public enum ProductDetail: String, UIElement {
        case scrollView = "productDetail.scrollView"
        case image = "productDetail.image"
        case title = "productDetail.title"
        case price = "productDetail.price"
        case description = "productDetail.description"
    }

    /// Loading, empty and error states, shared by every screen.
    public enum StateView: String, UIElement {
        case container = "stateView.container"
        case message = "stateView.message"
        case retryButton = "stateView.retryButton"
    }
}
