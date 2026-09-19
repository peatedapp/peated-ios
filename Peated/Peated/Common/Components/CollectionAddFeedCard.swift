import PeatedCore
import SwiftUI

/// Bottles a member added to a collection, as compact rows under the header.
struct CollectionAddFeedCard: View {
    let item: CollectionAddFeedItem
    let onUserTap: () -> Void
    let onBottleTap: (ActivityBottleSummary) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ActivityEntryHeader(
                avatarUrl: item.userAvatarUrl,
                actor: item.username,
                action: item.actionText,
                timeAgo: item.createdAt.timeAgo,
                onTap: onUserTap
            )

            VStack(alignment: .leading, spacing: 0) {
                ForEach(item.bottles, id: \.id) { bottle in
                    CompactBottleIdentityRow(bottle: bottle) {
                        onBottleTap(bottle)
                    }
                }

                if item.hiddenBottleCount > 0 {
                    Text(item.hiddenBottleCount == 1 ? "1 more bottle" : "\(item.hiddenBottleCount) more bottles")
                        .font(.peatedInteractiveSmall)
                        .foregroundColor(.textSecondary)
                        .padding(.top, 4)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}
