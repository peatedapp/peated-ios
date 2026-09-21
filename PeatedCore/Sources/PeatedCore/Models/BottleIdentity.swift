import Foundation

/// The three identity lines every bottle row shows: the marketed name, where it
/// comes from, and its release facts. Built once from the API bottle so rows and
/// cached tastings render the same text as the web.
public struct BottleIdentity: Hashable, Sendable, Codable {
    public let name: String
    /// Distillers other than the brand, then the category.
    public let provenance: [String]
    /// Release fact, release year, age or NAS, and ABV, in that order.
    public let metadata: [String]

    public init(name: String, provenance: [String], metadata: [String]) {
        self.name = name
        self.provenance = provenance
        self.metadata = metadata
    }

    public init(bottle: Bottle) {
        let releaseFact = BottleDisplayName.releaseMetadata(for: bottle)
        let releaseYear = bottle.releaseYear.map { "\($0) release" }
        let distillers: [String] = if bottle.distillers.count > 3 {
            ["\(bottle.distillers.count) distilleries"]
        } else {
            bottle.distillers.filter { $0.id != bottle.brand.id }.map(\.name)
        }
        let age: String? = if let statedAge = bottle.statedAge {
            "\(statedAge) years"
        } else if bottle.noAgeStatement == true {
            "NAS"
        } else {
            nil
        }

        self.init(
            name: BottleDisplayName.format(bottle),
            provenance: distillers + [BottleDisplayName.categoryName(bottle.category)].compactMap(\.self),
            metadata: [
                releaseFact != releaseYear ? releaseFact : nil,
                releaseYear,
                age,
                bottle.abv.map(BottleDisplayName.formattedAbv)
            ].compactMap(\.self)
        )
    }
}
