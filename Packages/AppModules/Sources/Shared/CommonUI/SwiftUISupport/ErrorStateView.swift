import CommonKit
import SwiftUI

/// The SwiftUI counterpart of `StateContainerView.showMessage`.
public struct ErrorStateView: View {
    private let error: ErrorDisplayModel
    private let retry: () -> Void

    public init(error: ErrorDisplayModel, retry: @escaping () -> Void) {
        self.error = error
        self.retry = retry
    }

    public var body: some View {
        VStack(spacing: StateLayout.spacing) {
            Text(error.title).font(.headline)
            Text(error.message).font(.subheadline).foregroundStyle(.secondary)
            Button(AppStrings.Common.tryAgain, action: retry)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, StateLayout.minimumHorizontalInset)
    }
}
