import PeatedCore
import SwiftUI

struct BottleRow: View {
    let bottle: Bottle
    let isSelected: Bool
    let subtitle: BottleRowSubtitle?
    let onTap: () -> Void

    enum BottleRowSubtitle {
        case rating
        case lastTasting(TastingFeedItem)

        @ViewBuilder
        var view: some View {
            switch self {
            case .rating:
                EmptyView() // Handled in main view
            case let .lastTasting(tasting):
                HStack(spacing: DesignSystem.Spacing.xSmall) {
                    if let band = tasting.ratingBand {
                        TastingRatingView(band: band, fontSize: DesignSystem.FontSize.tiny)
                    }

                    Text("Last: \(tasting.timeAgo)")
                        .font(.system(size: DesignSystem.FontSize.small))
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    init(
        bottle: Bottle,
        isSelected: Bool = false,
        subtitle: BottleRowSubtitle? = nil,
        onTap: @escaping () -> Void
    ) {
        self.bottle = bottle
        self.isSelected = isSelected
        self.subtitle = subtitle
        self.onTap = onTap
    }

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignSystem.Spacing.medium) {
                // Bottle image
                BottleImage(imageUrl: bottle.imageUrl)
                    .frame(
                        width: DesignSystem.ImageSize.bottleThumb.width,
                        height: DesignSystem.ImageSize.bottleThumb.height
                    )

                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxSmall) {
                    // Bottle name with proper truncation
                    Text(bottle.fullName)
                        .font(.system(size: DesignSystem.FontSize.title, weight: .semibold, design: .default))
                        .foregroundColor(.text)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)

                    // Brand • Category on one line
                    HStack(spacing: DesignSystem.Spacing.xSmall) {
                        Text(bottle.brandName)
                            .font(.system(size: DesignSystem.FontSize.body))
                            .foregroundColor(.textSecondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .layoutPriority(1)

                        if let category = bottle.category {
                            Text("•")
                                .font(.system(size: DesignSystem.FontSize.body))
                                .foregroundColor(.textMuted)

                            Text(category.replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(.system(size: DesignSystem.FontSize.body))
                                .foregroundColor(.textSecondary)
                                .lineLimit(1)
                        }
                    }

                    // Subtitle content
                    if let subtitle {
                        if case .rating = subtitle, bottle.ratingSummary.presentedCount > 0 {
                            BottleRatingSummaryView(summary: bottle.ratingSummary)
                        } else {
                            subtitle.view
                        }
                    }
                }

                Spacer(minLength: DesignSystem.Spacing.small)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.brand)
                        .font(.system(size: 20))
                }
            }
            .bottleCardStyle(isSelected: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Bottle Image Component

struct BottleImage: View {
    let imageUrl: String?

    var body: some View {
        if let imageUrl, let url = URL(string: imageUrl) {
            CachedAsyncImage(url: url) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                defaultBottleIcon
            }
            .task(id: imageUrl) {
                ImagePrefetcher.prefetch(urls: [url], max: 1)
            }
        } else {
            defaultBottleIcon
        }
    }

    private var defaultBottleIcon: some View {
        Image(systemName: "wineglass")
            .font(.system(size: 18))
            .foregroundColor(.brand.opacity(DesignSystem.Opacity.strong))
    }
}
