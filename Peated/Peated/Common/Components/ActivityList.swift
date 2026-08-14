import PeatedCore
import SwiftUI

/// A thin wrapper that renders a list of tastings using the unified feed design
/// from `TastingFeedCard`, with optional bottle suppression and item limiting.
struct ActivityList: View {
    let tastings: [TastingFeedItem]
    var showBottle: Bool = true
    var showUserHeader: Bool = true
    var limit: Int?

    let onToast: (TastingFeedItem) -> Void
    let onComment: (TastingFeedItem) -> Void
    let onUserTap: (TastingFeedItem) -> Void
    let onBottleTap: (TastingFeedItem) -> Void

    private var items: [TastingFeedItem] {
        if let limit {
            return Array(tastings.prefix(limit))
        }
        return tastings
    }

    var body: some View {
        VStack(spacing: 0) {
            ForEach(items) { tasting in
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
            }
        }
    }
}
