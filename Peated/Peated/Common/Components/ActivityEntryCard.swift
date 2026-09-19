import PeatedCore
import SwiftUI

/// The person an activity row points at when their name or avatar is tapped.
struct ActivityActor: Hashable {
    let id: String
    let username: String
    let avatarUrl: String?
}

/// Renders one activity entry with the card that matches its kind.
struct ActivityEntryCard: View {
    let entry: ActivityFeedEntry
    let onToast: (TastingFeedItem) -> Void
    let onComment: (TastingFeedItem) -> Void
    let onUserTap: (ActivityActor) -> Void
    let onBottleTap: (_ bottleId: String) -> Void

    var body: some View {
        switch entry {
        case let .tasting(tasting):
            TastingFeedCard(
                tasting: tasting,
                onToast: { onToast(tasting) },
                onComment: { onComment(tasting) },
                onUserTap: {
                    onUserTap(ActivityActor(
                        id: tasting.userId,
                        username: tasting.username,
                        avatarUrl: tasting.userAvatarUrl
                    ))
                },
                onBottleTap: { onBottleTap(tasting.bottleId) }
            )
        case let .memberReview(review):
            MemberReviewFeedCard(
                review: review,
                onUserTap: {
                    onUserTap(ActivityActor(
                        id: review.userId,
                        username: review.username,
                        avatarUrl: review.userAvatarUrl
                    ))
                },
                onBottleTap: { onBottleTap(review.bottle.id) }
            )
        case let .criticReview(review):
            CriticReviewFeedCard(
                review: review,
                onBottleTap: { onBottleTap(review.bottle.id) }
            )
        case let .collectionAdd(item):
            CollectionAddFeedCard(
                item: item,
                onUserTap: {
                    onUserTap(ActivityActor(
                        id: item.userId,
                        username: item.username,
                        avatarUrl: item.userAvatarUrl
                    ))
                },
                onBottleTap: { onBottleTap($0.id) }
            )
        }
    }
}
