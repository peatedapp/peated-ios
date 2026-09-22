import PeatedCore
import SwiftUI

/// One tasting in an activity list: who tasted, the bottle with its band, the
/// notes and tasting notes, then the toast, comment, and share actions.
struct TastingFeedCard: View {
    let tasting: TastingFeedItem
    let showBottle: Bool
    let showUserHeader: Bool
    let onToast: () -> Void
    let onComment: () -> Void
    let onUserTap: () -> Void
    let onBottleTap: () -> Void
    /// What Report sends. Nil for the member's own tastings and for lists without reporting.
    let reportTarget: ReportTarget?

    @State private var showingImageViewer = false

    /// Default initializer with bottle shown
    init(
        tasting: TastingFeedItem,
        showBottle: Bool = true,
        showUserHeader: Bool = true,
        onToast: @escaping () -> Void,
        onComment: @escaping () -> Void,
        onUserTap: @escaping () -> Void,
        onBottleTap: @escaping () -> Void,
        reportTarget: ReportTarget? = nil
    ) {
        self.tasting = tasting
        self.showBottle = showBottle
        self.showUserHeader = showUserHeader
        self.onToast = onToast
        self.onComment = onComment
        self.onUserTap = onUserTap
        self.onBottleTap = onBottleTap
        self.reportTarget = reportTarget
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if showUserHeader {
                ActivityEntryHeader(
                    avatarUrl: tasting.userAvatarUrl,
                    actor: tasting.username,
                    action: "tasted",
                    timeAgo: tasting.createdAt.timeAgo,
                    onTap: onUserTap
                )
            }

            if showBottle {
                ActivityBottleIdentityRow(
                    bottle: tasting.bottle,
                    photoUrl: tasting.imageUrl,
                    onPhotoTap: tasting.imageUrl == nil ? nil : { showingImageViewer = true },
                    onTap: onBottleTap
                ) {
                    if let band = tasting.ratingBand {
                        TastingRatingView(band: band)
                    }
                } details: {
                    details
                }
            } else {
                // On the bottle page the bottle is already known; keep the rating beside the notes.
                HStack(alignment: .top, spacing: 12) {
                    details
                    Spacer(minLength: 0)
                    if let band = tasting.ratingBand {
                        TastingRatingView(band: band)
                    }
                }
            }

            actions
                .padding(.top, 4)

            if !tasting.friendUsernames.isEmpty {
                Text(friendsText)
                    .font(.peatedMetadata)
                    .foregroundColor(.textSecondary)
                    .italic()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .fullScreenCover(isPresented: $showingImageViewer) {
            if let imageUrl = tasting.imageUrl {
                ImageViewer(imageUrl: imageUrl, isPresented: $showingImageViewer)
            }
        }
    }

    @ViewBuilder
    private var details: some View {
        let excerpt = tasting.notes?.activityPreview()
        if excerpt != nil || !tasting.tags.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                if let excerpt {
                    Text(excerpt)
                        .font(.peatedBody)
                        .foregroundColor(.text)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if !tasting.tags.isEmpty {
                    ActivityTagList(tags: tasting.tags)
                }
            }
        }
    }

    private var actions: some View {
        HStack(spacing: 28) {
            Button(action: onToast) {
                HStack(spacing: 5) {
                    Image(systemName: tasting.hasToasted ? "hands.clap.fill" : "hands.clap")
                        .font(.system(size: 17, weight: .light))
                    if tasting.toastCount > 0 {
                        Text("\(tasting.toastCount)")
                            .font(.peatedMetadata)
                    }
                }
                .foregroundColor(tasting.hasToasted ? .brand : .textSecondary)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel(tasting.hasToasted ? "Remove toast" : "Toast")
            .accessibilityValue(tasting.toastCount > 0 ? "\(tasting.toastCount)" : "")

            Button(action: onComment) {
                HStack(spacing: 5) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 17, weight: .light))
                    if tasting.commentCount > 0 {
                        Text("\(tasting.commentCount)")
                            .font(.peatedMetadata)
                    }
                }
                .foregroundColor(.textSecondary)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("Comments")
            .accessibilityValue(tasting.commentCount > 0 ? "\(tasting.commentCount)" : "")

            Spacer()

            ShareLink(item: PeatedWebURL.tasting(id: tasting.id)) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 17, weight: .light))
                    .foregroundColor(.textSecondary)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("Share tasting")

            if let reportTarget {
                OverflowMenu(.inline, subject: "tasting") {
                    ReportMenuItem(target: reportTarget)
                }
            }
        }
    }

    private var friendsText: String {
        let friends = tasting.friendUsernames
        if friends.count == 1 {
            return "@\(friends[0]) also enjoyed this"
        } else if friends.count == 2 {
            return "@\(friends[0]) and @\(friends[1]) also enjoyed this"
        } else if friends.count > 2 {
            return "@\(friends[0]), @\(friends[1]) and \(friends.count - 2) others also enjoyed this"
        }
        return ""
    }
}
