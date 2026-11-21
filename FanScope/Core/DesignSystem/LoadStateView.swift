import SwiftUI

struct LoadStateView<Value: Sendable, Content: View>: View {
    let state: LoadState<Value>
    let emptyTitle: LocalizedStringKey
    let emptySystemImage: String
    let emptyDescription: LocalizedStringKey
    let onRetry: () -> Void
    @ViewBuilder let content: (Value) -> Content

    var body: some View {
        switch state {
        case .idle, .loading:
            ProgressView()
                .controlSize(.regular)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let value):
            content(value)
        case .empty:
            ContentUnavailableView(
                emptyTitle,
                systemImage: emptySystemImage,
                description: Text(emptyDescription)
            )
        case .failed(let message):
            ContentUnavailableView {
                Label("error.unable_to_load", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("action.try_again", action: onRetry)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}
