import SwiftUI

/// The "who did what, when" line shared by every activity row: avatar, actor,
/// action, and relative time in the web's metadata style.
struct ActivityEntryHeader: View {
    let avatarUrl: String?
    let actor: String
    let action: String
    let timeAgo: String
    /// Opens the actor's profile, or the source review for critics.
    var onTap: (() -> Void)?
    var accessibilityHint: String = "Opens profile"

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            if let onTap {
                Button(action: onTap) {
                    AvatarImage(urlString: avatarUrl, size: 26)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel(actor)
                .accessibilityHint(accessibilityHint)

                Button(action: onTap) {
                    line
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("\(actor) \(action), \(timeAgo)")
                .accessibilityHint(accessibilityHint)
            } else {
                AvatarImage(urlString: avatarUrl, size: 26)

                line
                    .accessibilityLabel("\(actor) \(action), \(timeAgo)")
            }

            Spacer(minLength: 0)
        }
    }

    private var line: some View {
        (
            Text(actor)
                .font(.peatedInteractiveSmall)
                .foregroundColor(.brandEmphasis)
                + Text(" \(action)")
                .font(.peatedMetadata)
                .foregroundColor(.textSecondary)
                + Text(" · \(timeAgo)")
                .font(.peatedMetadata)
                .foregroundColor(.textSecondary)
        )
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
    }
}
