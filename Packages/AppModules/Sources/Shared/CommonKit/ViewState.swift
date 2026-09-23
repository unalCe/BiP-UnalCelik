import Foundation

public enum ViewState<Value: Equatable>: Equatable {
    case idle
    case loading
    case loaded(Value)
    case empty
    case failed(ErrorDisplayModel)
}

public extension ViewState {
    var value: Value? {
        if case .loaded(let value) = self { return value }
        return nil
    }

    var failure: ErrorDisplayModel? {
        if case .failed(let error) = self { return error }
        return nil
    }

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    var isIdle: Bool {
        if case .idle = self { return true }
        return false
    }
}
