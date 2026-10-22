public enum BottleCategory: String, CaseIterable, Sendable {
    case blend
    case blendedGrain = "blended_grain"
    case blendedMalt = "blended_malt"
    case bourbon
    case corn
    case rye
    case singleGrain = "single_grain"
    case singleMalt = "single_malt"
    case singlePotStill = "single_pot_still"
    case wheat

    /// Matches the web label, so "blend" reads as "Blended Whisky".
    public var displayName: String {
        BottleDisplayName.categoryName(rawValue) ?? rawValue
    }
}

public struct CreateBottleInput: Equatable, Sendable {
    public let name: String
    public let brandName: String
    public let category: BottleCategory?
    public let statedAge: Int?
    public let abv: Double?

    public init(
        name: String,
        brandName: String,
        category: BottleCategory? = nil,
        statedAge: Int? = nil,
        abv: Double? = nil
    ) {
        self.name = name
        self.brandName = brandName
        self.category = category
        self.statedAge = statedAge
        self.abv = abv
    }
}
