import PeatedCore
import SwiftUI

/// The end of a paginated list: a spinner while the next page loads, or a retry
/// button when it failed. It shows nothing once the last page has loaded.
struct PagedListFooter<Item: Identifiable & Sendable>: View {
    let list: PagedList<Item>

    var body: some View {
        Group {
            if list.error != nil, !list.items.isEmpty {
                VStack(spacing: 8) {
                    Text("Couldn't load more")
                        .font(.footnote)
                        .foregroundColor(.textSecondary)
                    Button("Retry") {
                        Task { await list.loadMore() }
                    }
                    .buttonStyle(.bordered)
                }
            } else if list.isLoading, list.hasMore {
                ProgressView()
                    .tint(.brand)
                    .accessibilityLabel("Loading more")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

extension View {
    /// Starts the next page when this row appears near the end of `list`.
    ///
    /// The load runs in its own task so scrolling the row away does not cancel
    /// a request that is already in flight.
    func loadsMore<Item: Identifiable & Sendable>(of list: PagedList<Item>, after item: Item) -> some View {
        onAppear {
            Task { await list.loadMoreIfNeeded(after: item) }
        }
    }
}
