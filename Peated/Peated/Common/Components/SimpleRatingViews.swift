import PeatedCore
import SwiftUI

struct SimpleRatingView: View {
    let rating: Double
    var showLabel = false
    var iconSize: CGFloat = 14

    var body: some View {
        if let value = RatingValue(rating: rating), value != .none {
            HStack(spacing: 3) {
                HStack(spacing: 2) {
                    ForEach(0 ..< value.iconCount, id: \.self) { _ in
                        Image(systemName: value == .pass ? "hand.thumbsdown.fill" : "hand.thumbsup.fill")
                            .font(.system(size: iconSize))
                    }
                }

                if showLabel {
                    Text(value.displayName)
                        .fontWeight(.medium)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(value.displayName)
        }
    }
}

struct AverageRatingIndicator: View {
    let average: Double
    var iconSize: CGFloat = 14

    private var iconFills: [Double] {
        if average < 0 {
            return [min(abs(average), 1)]
        }

        return [
            min(max(average, 0), 1),
            min(max(average - 1, 0), 1)
        ]
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(Array(iconFills.enumerated()), id: \.offset) { _, fill in
                Image(systemName: average < 0 ? "hand.thumbsdown.fill" : "hand.thumbsup.fill")
                    .font(.system(size: iconSize))
                    .foregroundColor(.brand.opacity(0.25 + (0.75 * fill)))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Average rating \(average, specifier: "%.2f")")
    }
}

struct CommunityRatingView: View {
    let average: Double?
    let total: Int
    var showCount = true
    var fontSize = DesignSystem.FontSize.small

    var body: some View {
        if total > 0, let average {
            HStack(spacing: 5) {
                AverageRatingIndicator(average: average, iconSize: fontSize)

                Text(average, format: .number.precision(.fractionLength(2)))
                    .font(.system(size: fontSize, weight: .medium))

                if showCount {
                    Text("(\(total))")
                        .font(.system(size: fontSize))
                        .foregroundColor(.textSecondary)
                }
            }
            .foregroundColor(.text)
        }
    }
}

struct BottleRatingStatsView: View {
    let stats: BottleRatingStats

    var body: some View {
        if stats.total == 0 {
            Text("No ratings yet")
                .font(.system(size: DesignSystem.FontSize.small))
                .foregroundColor(.textSecondary)
        } else {
            VStack(spacing: 8) {
                ratingRow(label: "Savor", value: 2, count: stats.savor, percentage: stats.percentages.savor)
                ratingRow(label: "Sip", value: 1, count: stats.sip, percentage: stats.percentages.sip)
                ratingRow(label: "Pass", value: -1, count: stats.pass, percentage: stats.percentages.pass)
            }
        }
    }

    private func ratingRow(label: String, value: Double, count: Int, percentage: Double) -> some View {
        HStack(spacing: 10) {
            HStack(spacing: 5) {
                SimpleRatingView(rating: value, iconSize: 12)
                Text(label)
                    .font(.system(size: DesignSystem.FontSize.small, weight: .medium))
            }
            .frame(width: 72, alignment: .leading)

            ProgressView(value: min(max(percentage, 0), 100), total: 100)
                .tint(.brand)

            Text("\(count) (\(Int(percentage.rounded()))%)")
                .font(.system(size: DesignSystem.FontSize.caption))
                .foregroundColor(.textSecondary)
                .frame(width: 72, alignment: .trailing)
        }
    }
}
