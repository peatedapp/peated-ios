import PeatedCore
import SwiftUI

/// A published critic review in the global feed. The score keeps the
/// publication's own scale, and the header opens the review on their site.
struct CriticReviewFeedCard: View {
    let review: CriticReviewFeedItem
    let onBottleTap: () -> Void

    @Environment(\.openURL) private var openURL

    private var reviewURL: URL? {
        URL(string: review.url)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ActivityEntryHeader(
                avatarUrl: review.sourceImageUrl,
                actor: review.sourceName,
                action: "published a review",
                timeAgo: review.createdAt.timeAgo,
                onTap: reviewURL.map { url in { openURL(url) } as () -> Void },
                accessibilityHint: "Opens the review in the browser"
            )

            ActivityBottleIdentityRow(bottle: review.bottle, onTap: onBottleTap) {
                if let score = review.score {
                    ReviewScoreView(score: score)
                }
            } details: {
                let excerpt = review.excerpt?.activityPreview()
                if excerpt != nil || !review.tags.isEmpty || review.byline != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        if let excerpt {
                            Text(excerpt)
                                .font(.peatedBodyText)
                                .foregroundColor(.text)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if !review.tags.isEmpty {
                            ActivityTagList(tags: review.tags)
                        }

                        if let byline = review.byline {
                            Text("By \(byline)")
                                .font(.peatedMetadata)
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}
