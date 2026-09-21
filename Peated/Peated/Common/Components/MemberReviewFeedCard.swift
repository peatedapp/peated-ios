import PeatedCore
import SwiftUI

/// A member's bottle review in the activity feed: the bottle with its 0–100
/// score and band, then the review text and tasting notes.
struct MemberReviewFeedCard: View {
    let review: MemberReviewFeedItem
    let onUserTap: () -> Void
    let onBottleTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ActivityEntryHeader(
                avatarUrl: review.userAvatarUrl,
                actor: review.username,
                action: "reviewed",
                timeAgo: review.createdAt.timeAgo,
                onTap: onUserTap
            )

            ActivityBottleIdentityRow(bottle: review.bottle, onTap: onBottleTap) {
                ReviewScoreView(score: review.score)
            } details: {
                let excerpt = review.notes?.activityPreview()
                if excerpt != nil || !review.tags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        if let excerpt {
                            Text(excerpt)
                                .font(.peatedBody)
                                .foregroundColor(.text)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if !review.tags.isEmpty {
                            ActivityTagList(tags: review.tags)
                        }
                    }
                }
            }

            HStack {
                Spacer()

                ShareLink(item: PeatedWebURL.memberReview(id: review.id)) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 17, weight: .light))
                        .foregroundColor(.textSecondary)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("Share review")
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}
