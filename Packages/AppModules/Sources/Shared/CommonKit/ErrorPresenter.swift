import Foundation
import ProductDomain

public struct ErrorPresenter: Sendable {
    public init() {}

    public func display(for error: Error) -> ErrorDisplayModel {
        guard let domainError = error as? DomainError else {
            return .generic
        }

        switch domainError {
        case .server(let message):
            return ErrorDisplayModel(
                title: AppStrings.Error.genericTitle,
                message: message
            )
        case .offline:
            return ErrorDisplayModel(
                title: AppStrings.Error.offlineTitle,
                message: AppStrings.Error.offlineMessage
            )
        case .invalidData:
            return ErrorDisplayModel(
                title: AppStrings.Error.invalidDataTitle,
                message: AppStrings.Error.invalidDataMessage
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
            message: AppStrings.Error.genericMessage
        )
    }
}
