import Foundation
import ProductDomain

public struct ErrorPresenter: Sendable {
    public init() {}

    public func display(for error: any Error) -> ErrorDisplayModel {
        guard let domainError = error as? DomainError else {
            return .generic
        }

        switch domainError {
        case .notFound:
            return ErrorDisplayModel(
                title: "Product not found",
                message: "This product is no longer available.",
                isRetryable: false
            )
        case .offline:
            return ErrorDisplayModel(
                title: "You're offline",
                message: "Check your connection and try again.",
                isRetryable: true
            )
        case .invalidData:
            return ErrorDisplayModel(
                title: "Couldn't read the response",
                message: "Please try again later.",
                isRetryable: true
            )
        case .unknown:
            return .generic
        }
    }
}

private extension ErrorDisplayModel {
    static let generic = ErrorDisplayModel(
        title: "Something went wrong",
        message: "Please try again.",
        isRetryable: true
    )
}
