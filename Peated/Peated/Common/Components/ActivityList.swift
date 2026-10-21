import PeatedCore
import SwiftUI

/// A thin wrapper that renders a list of tastings using the unified feed design
/// from `TastingFeedCard`, with optional bottle suppression.
///
/// Rows are lazy so a paginated list only builds what is on screen. Pass
/// `onAppear` to start the next page as rows scroll in.
struct ActivityList: View {
    let tastings: [TastingFeedItem]
    var showBottle: Bool = true
    var showUserHeader: Bool = true
    var onAppear: ((TastingFeedItem) -> Void)?

    let onToast: (TastingFeedItem) -> Void
    let onComment: (TastingFeedItem) -> Void
    let onUserTap: (TastingFeedItem) -> Void
    let onBottleTap: (TastingFeedItem) -> Void

    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(tastings) { tasting in
                TastingFeedCard(
                    tasting: tasting,
                    showBottle: showBottle,
                    showUserHeader: showUserHeader,
                    onToast: { onToast(tasting) },
                    onComment: { onComment(tasting) },
                    onUserTap: { onUserTap(tasting) },
                    onBottleTap: { onBottleTap(tasting) }
                )
                .overlay(
                    Rectangle()
                        .fill(Color.border)
                        .frame(height: 0.5)
                        .padding(.horizontal, 20),
                    alignment: .bottom
                )
                .onAppear { onAppear?(tasting) }
            }
        }
    }
}
