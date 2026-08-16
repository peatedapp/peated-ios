import PeatedCore
import SwiftUI

struct BottleSupplementalDetails: View {
    let bottle: Bottle

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            producerTastingNotes

            if hasDetails {
                VStack(alignment: .leading, spacing: 12) {
                    sectionTitle("DETAILS")
                    identityDetails
                    producerDetails
                    communityRating
                }
            }
        }
    }

    @ViewBuilder
    private var producerTastingNotes: some View {
        if let notes = bottle.tastingNotes {
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle("TASTING NOTES")
                detailRow(label: "Nose", value: notes.nose)
                detailRow(label: "Palate", value: notes.palate)
                detailRow(label: "Finish", value: notes.finish)
            }
        }
    }

    @ViewBuilder
    private var identityDetails: some View {
        if let edition = bottle.edition, !edition.isEmpty {
            detailRow(label: "Edition", value: edition)
        }
        if let series = bottle.series {
            detailRow(label: "Series", value: series.name)
        }
        if let vintageYear = bottle.vintageYear {
            detailRow(label: "Vintage", value: String(vintageYear))
        }
        if let releaseYear = bottle.releaseYear {
            detailRow(label: "Released", value: String(releaseYear))
        }
        if let caskDetails {
            detailRow(label: "Cask", value: caskDetails)
        }
    }

    @ViewBuilder
    private var producerDetails: some View {
        let distillers = bottle.distillers.filter { $0.id != bottle.brand.id }
        if !distillers.isEmpty {
            detailRow(label: "Distilled by", value: distillers.map(\.name).joined(separator: ", "))
        }
        if let bottler = bottle.bottler, bottler.id != bottle.brand.id {
            detailRow(label: "Bottled by", value: bottler.name)
        }
        if bottle.caskStrength || bottle.singleCask {
            HStack(spacing: 12) {
                if bottle.caskStrength {
                    characteristic("Cask Strength")
                }
                if bottle.singleCask {
                    characteristic("Single Cask")
                }
            }
        }
    }

    @ViewBuilder
    private var communityRating: some View {
        if bottle.totalRatings > 0 {
            VStack(alignment: .leading, spacing: 6) {
                CommunityRatingView(
                    average: bottle.avgRating,
                    total: bottle.totalRatings,
                    showCount: false,
                    fontSize: DesignSystem.FontSize.large
                )

                Text(
                    "\(bottle.totalRatings) \(bottle.totalRatings == 1 ? "rating" : "ratings") from the community"
                )
                .font(.system(size: DesignSystem.FontSize.small))
                .foregroundColor(.textSecondary)

                BottleRatingStatsView(stats: bottle.ratingStats)
                    .padding(.top, 6)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.surface.opacity(0.5))
            .cornerRadius(8)
        }
    }

    private var hasDetails: Bool {
        bottle.edition != nil
            || bottle.series != nil
            || bottle.vintageYear != nil
            || bottle.releaseYear != nil
            || bottle.caskType != nil
            || bottle.caskSize != nil
            || bottle.caskFill != nil
            || bottle.caskStrength
            || bottle.singleCask
            || bottle.distillers.contains { $0.id != bottle.brand.id }
            || (bottle.bottler != nil && bottle.bottler?.id != bottle.brand.id)
            || bottle.totalRatings > 0
    }

    private var caskDetails: String? {
        let values = [bottle.caskFill, bottle.caskType, bottle.caskSize]
            .compactMap(\.self)
            .map { $0.replacingOccurrences(of: "_", with: " ").capitalized }
        return values.isEmpty ? nil : values.joined(separator: " · ")
    }

    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.system(size: DesignSystem.FontSize.small))
            .fontWeight(.semibold)
            .foregroundColor(.textSecondary)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(label)
                .font(.system(size: DesignSystem.FontSize.small, weight: .medium))
                .foregroundColor(.textSecondary)
                .frame(width: 82, alignment: .leading)

            Text(value)
                .font(.system(size: DesignSystem.FontSize.body))
                .foregroundColor(.text)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func characteristic(_ name: String) -> some View {
        Label(name, systemImage: "checkmark.circle.fill")
            .font(.system(size: DesignSystem.FontSize.small))
            .foregroundColor(.success)
    }
}
