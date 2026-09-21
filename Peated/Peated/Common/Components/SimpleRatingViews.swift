import PeatedCore
import SwiftUI

/// Rating sizes shared by tasting bands and review scores, matching the web's sm, md, and lg.
enum RatingSize {
    case small
    case medium
    case large

    var labelFont: Font {
        switch self {
        case .small: .peatedRatingLabelSmall
        case .medium: .peatedRatingLabel
        case .large: .peatedRatingLabelLarge
        }
    }
}

/// One tasting's named rating and its range, never a five-point score.
/// Small keeps the label and range inline for compact metadata rows.
struct TastingRatingView: View {
    let band: TastingRatingBand
    var size: RatingSize = .medium

    private var rangeText: String {
        "\(band.scoreRange.lowerBound)–\(band.scoreRange.upperBound) range"
    }

    var body: some View {
        Group {
            if size == .small {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    label
                    range
                }
            } else {
                VStack(alignment: .trailing, spacing: 2) {
                    label
                    range
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(band.displayName) rating, \(rangeText)")
    }

    private var label: some View {
        Text(band.displayName)
            .font(size.labelFont)
            .foregroundColor(.brandEmphasis)
            .lineLimit(1)
    }

    private var range: some View {
        Text(rangeText)
            .font(size == .large ? .system(size: 15) : .peatedMetadata)
            .monospacedDigit()
            .foregroundColor(.textSecondary)
            .lineLimit(1)
    }
}

/// One review's exact score on its own scale. Only a 100-point scale gets a Peated
/// rating name, so critic scores on other scales show the number alone.
struct ReviewScoreView: View {
    let value: Double
    let scale: Double
    let band: TastingRatingBand?
    var size: RatingSize = .medium

    /// A member review score, always on Peated's 100-point scale.
    init(score: Int, size: RatingSize = .medium) {
        value = Double(score)
        scale = 100
        band = TastingRatingBand(score: score)
        self.size = size
    }

    /// A critic's score as the publication shows it.
    init(score: CriticReviewFeedItem.Score, size: RatingSize = .medium) {
        value = score.value
        scale = score.scale
        band = score.ratingBand
        self.size = size
    }

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            if let band {
                Text(band.displayName)
                    .font(size.labelFont)
                    .foregroundColor(.brandEmphasis)
                    .lineLimit(1)
            }

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value.formatted())
                    .font(valueFont)
                    .foregroundColor(.text)
                Text("/\(scale.formatted())")
                    .font(.peatedMetadata)
                    .foregroundColor(.textSecondary)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var valueFont: Font {
        switch size {
        case .small: .peatedScoreValueSmall
        case .medium: .peatedScoreValue
        case .large: .peatedScoreValueLarge
        }
    }

    private var accessibilityLabel: String {
        let score = "\(value.formatted()) out of \(scale.formatted())"
        if let band {
            return "\(band.displayName) review score, \(score)"
        }
        return "Review score, \(score)"
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
                    .font(.custom(PeatedFontName.readingSemiBold, size: fontSize, relativeTo: .footnote))

                if let score = summary.medianScore {
                    Text("\(score)")
                        .font(.custom(PeatedFontName.display, size: fontSize, relativeTo: .footnote).monospacedDigit())
                } else {
                    Text(band.description)
                        .font(.custom(PeatedFontName.reading, size: fontSize, relativeTo: .footnote))
                        .foregroundColor(.textSecondary)
                }

                if showCount {
                    Text("(\(summary.presentedCount))")
                        .font(.custom(PeatedFontName.reading, size: fontSize, relativeTo: .footnote))
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
                .font(.peatedMetadata)
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
                .font(.peatedInteractiveSmall)
                .frame(width: 92, alignment: .leading)

            Text(band.description)
                .font(.peatedCode)
                .foregroundColor(.textSecondary)

            Spacer()

            Text("\(count)")
                .font(.peatedCode)
                .foregroundColor(.textSecondary)
                .frame(minWidth: 28, alignment: .trailing)
        }
    }
}
