import Foundation
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
        if let bottlingYear = bottle.bottlingYear {
            detailRow(label: "Bottled", value: String(bottlingYear))
        }
        if let releaseYear = bottle.releaseYear {
            detailRow(label: "Released", value: releaseDate(year: releaseYear))
        }
        if let maturation = bottle.maturation, !maturation.isEmpty {
            detailRow(label: "Maturation", value: maturation)
        }
        if let caskNumber = bottle.caskNumber, !caskNumber.isEmpty {
            detailRow(label: "Cask number", value: caskNumber)
        }
        if let outturn = bottle.outturn {
            detailRow(label: "Outturn", value: "\(outturn) bottles")
        }
        if let ppm = bottle.maltPhenolPpm {
            detailRow(label: "Phenols", value: "\(ppm.formatted()) ppm")
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
        let characteristics = characteristics
        if !characteristics.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(characteristics, id: \.self) { name in
                    characteristic(name)
                }
            }
        }
    }

    @ViewBuilder
    private var communityRating: some View {
        if bottle.ratingSummary.presentedCount > 0 {
            VStack(alignment: .leading, spacing: 10) {
                BottleRatingSummaryView(
                    summary: bottle.ratingSummary,
                    showCount: false,
                    fontSize: DesignSystem.FontSize.large
                )

                Text(ratingSummaryCaption)
                    .font(.system(size: DesignSystem.FontSize.small))
                    .foregroundColor(.textSecondary)

                if bottle.ratingSummary.reviewBandCounts.total > 0 {
                    Text("REVIEWS")
                        .font(.system(size: DesignSystem.FontSize.caption, weight: .semibold))
                        .foregroundColor(.textSecondary)
                    BottleRatingStatsView(counts: bottle.ratingSummary.reviewBandCounts)
                }

                if bottle.ratingSummary.tastingBandCounts.total > 0 {
                    Text("TASTINGS")
                        .font(.system(size: DesignSystem.FontSize.caption, weight: .semibold))
                        .foregroundColor(.textSecondary)
                    BottleRatingStatsView(counts: bottle.ratingSummary.tastingBandCounts)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.surface.opacity(0.5))
            .cornerRadius(DesignSystem.CornerRadius.medium)
        }
    }

    private var hasDetails: Bool {
        bottle.edition != nil
            || bottle.series != nil
            || bottle.vintageYear != nil
            || bottle.bottlingYear != nil
            || bottle.releaseYear != nil
            || bottle.maturation != nil
            || bottle.caskNumber != nil
            || bottle.outturn != nil
            || bottle.maltPhenolPpm != nil
            || bottle.caskStrength
            || bottle.singleCask
            || bottle.naturalColor == true
            || bottle.nonChillFiltered == true
            || bottle.noAgeStatement == true
            || bottle.distillers.contains { $0.id != bottle.brand.id }
            || (bottle.bottler != nil && bottle.bottler?.id != bottle.brand.id)
            || bottle.ratingSummary.presentedCount > 0
    }

    private var characteristics: [String] {
        var values: [String] = []
        if bottle.caskStrength {
            values.append("Cask Strength")
        }
        if bottle.singleCask {
            values.append("Single Cask")
        }
        if bottle.naturalColor == true {
            values.append("Natural Color")
        }
        if bottle.nonChillFiltered == true {
            values.append("Non-Chill Filtered")
        }
        if bottle.noAgeStatement == true {
            values.append("No Age Statement")
        }
        return values
    }

    private var ratingSummaryCaption: String {
        let summary = bottle.ratingSummary
        if summary.medianScore != nil {
            return "Based on \(summary.scoreCount) published \(summary.scoreCount == 1 ? "review" : "reviews")"
        }
        let count = summary.tastingBandCounts.total
        return "Based on \(count) tasting \(count == 1 ? "rating" : "ratings")"
    }

    private func releaseDate(year: Int) -> String {
        guard let month = bottle.releaseMonth,
              Calendar(identifier: .gregorian).shortMonthSymbols.indices.contains(month - 1)
        else {
            return String(year)
        }

        let monthName = Calendar(identifier: .gregorian).shortMonthSymbols[month - 1]
        if let day = bottle.releaseDay {
            return "\(monthName) \(day), \(year)"
        }
        return "\(monthName) \(year)"
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
                .frame(width: 100, alignment: .leading)

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
