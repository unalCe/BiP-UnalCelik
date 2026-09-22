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
                title: AppStrings.Error.notFoundTitle,
                message: AppStrings.Error.notFoundMessage,
                isRetryable: false
            )
        case .offline:
            return ErrorDisplayModel(
                title: AppStrings.Error.offlineTitle,
                message: AppStrings.Error.offlineMessage,
                isRetryable: true
            )
        case .invalidData:
            return ErrorDisplayModel(
                title: AppStrings.Error.invalidDataTitle,
                message: AppStrings.Error.invalidDataMessage,
                isRetryable: true
            )
        case .unknown:
            return .generic
        }
    }
}

private extension ErrorDisplayModel {
    static var generic: ErrorDisplayModel {
        ErrorDisplayModel(
            title: AppStrings.Error.genericTitle,
            message: AppStrings.Error.genericMessage,
            isRetryable: true
        )
    }
}
