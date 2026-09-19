import PeatedCore
import SwiftUI

/// The activity variant of the bottle identity row: a feed thumbnail, then the
/// name, provenance, and release facts with the rating on the trailing edge,
/// and any review text or notes beneath the details without going under the image.
struct ActivityBottleIdentityRow<End: View, Details: View>: View {
    let bottle: ActivityBottleSummary
    /// A personal photo shown in place of the catalog image, cropped to fill.
    var photoUrl: String?
    var onPhotoTap: (() -> Void)?
    let onTap: () -> Void
    @ViewBuilder let end: () -> End
    @ViewBuilder let details: () -> Details

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            thumbnail

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Button(action: onTap) {
                        identity
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel(accessibilityLabel)
                    .accessibilityHint("Opens bottle")

                    Spacer(minLength: 0)

                    end()
                }

                details()
            }
        }
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let photoUrl, let onPhotoTap {
            Button(action: onPhotoTap) {
                ActivityBottleThumbnail(imageUrl: photoUrl, fit: .cover)
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("Photo")
            .accessibilityHint("Opens full screen")
        } else {
            ActivityBottleThumbnail(imageUrl: photoUrl ?? bottle.imageUrl, fit: photoUrl == nil ? .contain : .cover)
        }
    }

    private var identity: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(bottle.identity.name)
                    .font(.peatedRowTitle)
                    .foregroundColor(.text)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                BottleStatusIcons(bottleId: bottle.id)
            }

            if !bottle.identity.provenance.isEmpty {
                Text(bottle.identity.provenance.joined(separator: " · "))
                    .font(.peatedMetadata)
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
            }

            if !bottle.identity.metadata.isEmpty {
                Text(bottle.identity.metadata.joined(separator: " · "))
                    .font(.peatedMetadata)
                    .foregroundColor(.textSecondary)
                    .lineLimit(1)
            }
        }
    }

    private var accessibilityLabel: String {
        ([bottle.identity.name] + bottle.identity.provenance + bottle.identity.metadata).joined(separator: ", ")
    }
}

/// The compact variant for dense lists such as library additions: a small
/// thumbnail and one regular-weight name line.
struct CompactBottleIdentityRow: View {
    let bottle: ActivityBottleSummary
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 8) {
                ActivityBottleThumbnail(imageUrl: bottle.imageUrl, size: .compact)
                Text(bottle.identity.name)
                    .font(.peatedBodyText)
                    .foregroundColor(.text)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 4)
            .frame(minHeight: 44)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(bottle.identity.name)
        .accessibilityHint("Opens bottle")
    }
}
