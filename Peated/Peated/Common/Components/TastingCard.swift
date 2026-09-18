import PeatedCore
import SwiftUI

struct TastingCard: View {
    let tasting: TastingFeedItem
    let onToast: () -> Void
    let onComment: () -> Void // Used for navigating to tasting detail
    let onUserTap: () -> Void
    let onBottleTap: () -> Void // Also navigates to tasting detail

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main content
            VStack(alignment: .leading, spacing: 4) {
                // Bottle name
                Text(tasting.bottleName)
                    .font(.peatedDisplaySerif)
                    .foregroundColor(.text)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .onTapGesture {
                        onBottleTap()
                    }

                // Brand and category
                HStack(spacing: 4) {
                    Text(tasting.bottleBrandName)
                        .font(.system(size: 13))
                        .foregroundColor(.textSecondary)

                    if let category = tasting.bottleCategory {
                        Text("•")
                            .font(.system(size: 13))
                            .foregroundColor(.textMuted)

                        Text(category.capitalized)
                            .font(.system(size: 13))
                            .foregroundColor(.textSecondary)
                    }
                }
                .lineLimit(1)

                // Notes
                if let notes = tasting.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.system(size: 14))
                        .foregroundColor(.text)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .padding(.top, 4)
                }

                // Tags (muted style)
                if !tasting.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(tasting.tags, id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.peatedFootnote)
                                    .foregroundColor(.textSecondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.surfaceSubtle)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.top, 6)
                }

                // Tasting photo
                if let imageUrl = tasting.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case let .success(image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(maxHeight: 200)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        case .failure, .empty:
                            EmptyView()
                        @unknown default:
                            ProgressView()
                                .frame(height: 200)
                        }
                    }
                    .padding(.top, 8)
                    .onTapGesture {
                        onComment() // Navigate to detail when tapping photo
                    }
                }

                // User info and timestamp
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 0) {
                        // Tappable user info area
                        HStack(spacing: 6) {
                            AvatarImage(urlString: tasting.userAvatarUrl, size: 20)

                            Text(tasting.username)
                                .font(.system(size: 13))
                                .foregroundColor(.textSecondary)
                        }
                        .contentShape(Rectangle()) // Make user area tappable
                        .onTapGesture {
                            onUserTap()
                        }

                        Text(" • ")
                            .font(.system(size: 13))
                            .foregroundColor(.textMuted)

                        // Separate timestamp as tappable area
                        Text(tasting.timeAgo)
                            .font(.system(size: 13))
                            .foregroundColor(.textSecondary)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onComment() // Navigate to detail when tapping timestamp
                            }

                        Spacer()

                        // Actions (not tappable for user navigation)
                        HStack(spacing: 16) {
                            Button(action: onToast) {
                                HStack(spacing: 4) {
                                    Image(systemName: tasting.hasToasted ? "hands.clap.fill" : "hands.clap")
                                        .font(.system(size: 14))
                                    Text("\(tasting.toastCount)")
                                        .font(.system(size: 13))
                                }
                                .foregroundColor(tasting.hasToasted ? .brand : .textSecondary)
                            }
                            .buttonStyle(.plain)

                            Button(action: onComment) {
                                HStack(spacing: 4) {
                                    Image(systemName: "bubble.left")
                                        .font(.system(size: 14))
                                    Text("\(tasting.commentCount)")
                                        .font(.system(size: 13))
                                }
                                .foregroundColor(.textSecondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Friends who also tasted - on separate line
                    if !tasting.friendUsernames.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.textSecondary)

                            ForEach(Array(tasting.friendUsernames.prefix(3)), id: \.self) { friend in
                                Text("@\(friend)")
                                    .font(.system(size: 13))
                                    .foregroundColor(.brand)
                            }

                            if tasting.friendUsernames.count > 3 {
                                Text("and \(tasting.friendUsernames.count - 3) more")
                                    .font(.system(size: 13))
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                }
                .padding(.top, 8)
            }
            .padding(16)
        }
        .background(Color.clear)
        .cardStyle()
    }
}
