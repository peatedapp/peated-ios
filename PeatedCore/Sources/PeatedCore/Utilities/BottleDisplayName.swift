import Foundation

/// Formats the concise marketed bottle name and its supporting facts the same
/// way the web does, so a bottle reads identically on both surfaces.
public enum BottleDisplayName {
    /// The human-facing name: brand, series when not already in the name, then
    /// the expression with a worded or compact edition.
    public static func format(_ bottle: Bottle, includeBrand: Bool = true, includeSeries: Bool = true) -> String {
        let expression = releaseName(for: bottle)
        let brandName = bottle.brand.shortName.flatMap { $0.isEmpty ? nil : $0 } ?? bottle.brand.name
        let seriesName = bottle.series.flatMap { series in
            includesIdentityText(expression, series.name) ? nil : series.name
        }

        return [
            includeBrand ? brandName : nil,
            includeSeries ? seriesName : nil,
            expression
        ]
        .compactMap(\.self)
        .filter { !$0.isEmpty }
        .joined(separator: " ")
    }

    /// One exact release fact that belongs beside the title rather than inside it.
    public static func releaseMetadata(for bottle: Bottle) -> String? {
        if let edition = bottle.edition, isBatchEdition(edition) {
            return edition
        }
        if bottle.edition != nil {
            return nil
        }
        if let vintageYear = bottle.vintageYear {
            return "\(vintageYear) vintage"
        }
        if let releaseYear = bottle.releaseYear {
            return "\(releaseYear) release"
        }
        return nil
    }

    /// "single_malt" reads as "Single Malt"; "blend" reads as "Blended Whisky".
    public static func categoryName(_ category: String?) -> String? {
        guard let category, !category.isEmpty else { return nil }
        if category == "blend" {
            return "Blended Whisky"
        }
        return category
            .lowercased()
            .replacingOccurrences(of: "_", with: " ")
            .split(separator: " ", omittingEmptySubsequences: false)
            .map { word -> String in
                guard let first = word.first else { return "" }
                return first.uppercased() + word.dropFirst()
            }
            .joined(separator: " ")
    }

    public static func formattedAbv(_ abv: Double) -> String {
        String(format: "%.1f%% ABV", abv)
    }

    // MARK: - Pieces

    static func isBatchEdition(_ edition: String?) -> Bool {
        guard let edition else { return false }
        return edition.contains(#/^batch(?:\s+(?:no\.?|number))?\s+\S/#.ignoresCase())
    }

    private static func isCompactEditionCode(_ edition: String) -> Bool {
        edition.contains(#/\d/#) && edition.wholeMatch(of: #/[A-Za-z0-9]+(?:[./-][A-Za-z0-9]+)*/#) != nil
    }

    private static func includesIdentityText(_ value: String, _ candidate: String) -> Bool {
        value.lowercased().contains(candidate.lowercased())
    }

    /// The expression without stored facts that the metadata line already shows.
    private static func expressionName(for bottle: Bottle) -> String {
        if let groupName = bottle.groupName {
            return groupName
        }

        let metadataSegments = Set(
            [
                bottle.statedAge.map { "\($0)-year-old" },
                bottle.releaseYear.map { "\($0) Release" },
                bottle.vintageYear.map { "\($0) Vintage" },
                bottle.abv.map(formattedAbv),
                bottle.singleCask ? "Single Cask" : nil,
                bottle.caskStrength ? "Cask Strength" : nil
            ]
            .compactMap { $0?.lowercased() }
        )
        var titleSegments = bottle.name.components(separatedBy: " - ")

        while titleSegments.count > 1,
              let last = titleSegments.last,
              metadataSegments.contains(last.lowercased()) {
            titleSegments.removeLast()
        }

        let expression = titleSegments.joined(separator: " - ")
        return expression.isEmpty ? bottle.name : expression
    }

    private static func releaseName(for bottle: Bottle) -> String {
        let expression = expressionName(for: bottle)

        if let edition = bottle.edition, !isBatchEdition(edition) {
            if includesIdentityText(expression, edition) {
                return expression
            }
            let separator = isCompactEditionCode(edition) ? " " : " - "
            return "\(expression)\(separator)\(edition)"
        }

        return expression
    }
}
