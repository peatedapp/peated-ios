public enum BottleCategory: String, CaseIterable, Sendable {
    case blend
    case bourbon
    case rye
    case singleGrain = "single_grain"
    case singleMalt = "single_malt"
    case singlePotStill = "single_pot_still"
    case spirit

    public var displayName: String {
        switch self {
        case .blend: "Blend"
        case .bourbon: "Bourbon"
        case .rye: "Rye"
        case .singleGrain: "Single Grain"
        case .singleMalt: "Single Malt"
        case .singlePotStill: "Single Pot Still"
        case .spirit: "Spirit"
        }
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
