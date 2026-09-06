import PeatedCore
import SwiftUI

struct TastingRatingView: View {
    let band: TastingRatingBand
    var showRange = false
    var fontSize = DesignSystem.FontSize.small

    var body: some View {
        HStack(spacing: 5) {
            Text(band.displayName)
                .font(.system(size: fontSize, weight: .semibold))

            if showRange {
                Text(band.description)
                    .font(.system(size: fontSize))
                    .foregroundColor(.textSecondary)
            }
        }
        .foregroundColor(.brand)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rating: \(band.displayName), \(band.description)")
    }
}

struct BottleRatingSummaryView: View {
    let summary: BottleRatingSummary
    var showCount = true
    var fontSize = DesignSystem.FontSize.small

    var body: some View {
        if let band = summary.presentedBand, summary.presentedCount > 0 {
            HStack(spacing: 5) {
                Text(band.displayName)
                    .font(.system(size: fontSize, weight: .semibold))

                if let score = summary.medianScore {
                    Text("\(score)")
                        .font(.system(size: fontSize, weight: .medium, design: .monospaced))
                } else {
                    Text(band.description)
                        .font(.system(size: fontSize))
                        .foregroundColor(.textSecondary)
                }

                if showCount {
                    Text("(\(summary.presentedCount))")
                        .font(.system(size: fontSize))
                        .foregroundColor(.textSecondary)
                }
            }
            .foregroundColor(.text)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityLabel(for: band))
        }
    }

    private func accessibilityLabel(for band: TastingRatingBand) -> String {
        let count = summary.presentedCount
        if let score = summary.medianScore {
            let noun = count == 1 ? "review" : "reviews"
            return "Review score \(score) out of 100, \(band.displayName), based on \(count) \(noun)"
        }
        let noun = count == 1 ? "tasting" : "tastings"
        return "Tasting rating \(band.displayName), \(band.description), based on \(count) \(noun)"
    }
}

struct BottleRatingStatsView: View {
    let counts: RatingBandCounts

    var body: some View {
        if counts.total == 0 {
            Text("No ratings yet")
                .font(.system(size: DesignSystem.FontSize.small))
                .foregroundColor(.textSecondary)
        } else {
            VStack(spacing: 8) {
                ForEach(TastingRatingBand.allCases.reversed(), id: \.self) { band in
                    ratingRow(band: band, count: counts.count(for: band))
                }
            }
        }
    }

    private func ratingRow(band: TastingRatingBand, count: Int) -> some View {
        HStack(spacing: 10) {
            Text(band.displayName)
                .font(.system(size: DesignSystem.FontSize.small, weight: .medium))
                .frame(width: 92, alignment: .leading)

            Text(band.description)
                .font(.system(size: DesignSystem.FontSize.caption, design: .monospaced))
                .foregroundColor(.textSecondary)

            Spacer()

            Text("\(count)")
                .font(.system(size: DesignSystem.FontSize.small, weight: .medium, design: .monospaced))
                .foregroundColor(.textSecondary)
                .frame(minWidth: 28, alignment: .trailing)
        }
    }
}
