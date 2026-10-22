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
    /// A distillery picked from the catalog, or a new one the server creates with the bottle.
    public enum Distiller: Hashable, Sendable {
        case existing(id: Int, name: String)
        case new(name: String)

        public var name: String {
            switch self {
            case let .existing(_, name), let .new(name): name
            }
        }
    }

    public let name: String
    public let brandName: String
    public let category: BottleCategory?
    public let statedAge: Int?
    /// True only when the label is confirmed to have no age statement. False means "not stated".
    public let noAgeStatement: Bool
    public let abv: Double?
    public let edition: String?
    public let distillers: [Distiller]
    /// True only when the label says so. False means "not stated", not "no".
    public let singleCask: Bool
    /// True only when the label says so. False means "not stated", not "no".
    public let caskStrength: Bool
    public let vintageYear: Int?
    public let releaseYear: Int?

    public init(
        name: String,
        brandName: String,
        category: BottleCategory? = nil,
        statedAge: Int? = nil,
        noAgeStatement: Bool = false,
        abv: Double? = nil,
        edition: String? = nil,
        distillers: [Distiller] = [],
        singleCask: Bool = false,
        caskStrength: Bool = false,
        vintageYear: Int? = nil,
        releaseYear: Int? = nil
    ) {
        self.name = name
        self.brandName = brandName
        self.category = category
        self.statedAge = statedAge
        self.noAgeStatement = noAgeStatement
        self.abv = abv
        self.edition = edition
        self.distillers = distillers
        self.singleCask = singleCask
        self.caskStrength = caskStrength
        self.vintageYear = vintageYear
        self.releaseYear = releaseYear
    }
}
