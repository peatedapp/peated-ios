import Foundation

public struct Brand: Codable, Equatable, Sendable {
    public let id: String
    public let name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

public struct BottleSeriesSummary: Codable, Equatable, Sendable {
    public let id: String
    public let name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

public struct BottleTastingNotes: Codable, Equatable, Sendable {
    public let nose: String
    public let palate: String
    public let finish: String

    public init(nose: String, palate: String, finish: String) {
        self.nose = nose
        self.palate = palate
        self.finish = finish
    }
}

public struct BottleRatingStats: Codable, Equatable, Sendable {
    public struct Percentages: Codable, Equatable, Sendable {
        public let pass: Double
        public let sip: Double
        public let savor: Double

        public init(pass: Double = 0, sip: Double = 0, savor: Double = 0) {
            self.pass = pass
            self.sip = sip
            self.savor = savor
        }
    }

    public let pass: Int
    public let sip: Int
    public let savor: Int
    public let total: Int
    public let average: Double?
    public let percentages: Percentages

    public init(
        pass: Int = 0,
        sip: Int = 0,
        savor: Int = 0,
        total: Int = 0,
        average: Double? = nil,
        percentages: Percentages = Percentages()
    ) {
        self.pass = pass
        self.sip = sip
        self.savor = savor
        self.total = total
        self.average = average
        self.percentages = percentages
    }
}

public struct TastingTag: Codable, Equatable, Hashable, Sendable, Identifiable {
    public let name: String
    public let category: String
    public let synonyms: [String]
    public let usageCount: Int

    public var id: String {
        name
    }

    public init(name: String, category: String, synonyms: [String] = [], usageCount: Int = 0) {
        self.name = name
        self.category = category
        self.synonyms = synonyms
        self.usageCount = usageCount
    }
}

public struct Bottle: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let fullName: String
    public let brand: Brand
    public let category: String?
    public let description: String?
    public let edition: String?
    public let series: BottleSeriesSummary?
    public let caskStrength: Bool
    public let singleCask: Bool
    public let statedAge: Int?
    public let vintageYear: Int?
    public let releaseYear: Int?
    public let caskType: String?
    public let caskSize: String?
    public let caskFill: String?
    public let distillers: [Brand]
    public let bottler: Brand?
    public let tastingNotes: BottleTastingNotes?
    public let suggestedTags: [String]

    // Additional properties for UI
    public let imageUrl: String?
    public let abv: Double?
    public let avgRating: Double?
    public let ratingStats: BottleRatingStats
    public let totalRatings: Int
    public let totalTastings: Int
    public var isFavorite: Bool
    public var isLibrary: Bool
    public var hasTasted: Bool

    public var brandName: String {
        brand.name
    }

    public init(
        id: String,
        name: String,
        fullName: String,
        brand: Brand,
        category: String? = nil,
        description: String? = nil,
        edition: String? = nil,
        series: BottleSeriesSummary? = nil,
        caskStrength: Bool = false,
        singleCask: Bool = false,
        statedAge: Int? = nil,
        vintageYear: Int? = nil,
        releaseYear: Int? = nil,
        caskType: String? = nil,
        caskSize: String? = nil,
        caskFill: String? = nil,
        distillers: [Brand] = [],
        bottler: Brand? = nil,
        tastingNotes: BottleTastingNotes? = nil,
        suggestedTags: [String] = [],
        imageUrl: String? = nil,
        abv: Double? = nil,
        avgRating: Double? = nil,
        ratingStats: BottleRatingStats? = nil,
        totalRatings: Int = 0,
        totalTastings: Int? = nil,
        isFavorite: Bool = false,
        isLibrary: Bool = false,
        hasTasted: Bool = false
    ) {
        self.id = id
        self.name = name
        self.fullName = fullName
        self.brand = brand
        self.category = category
        self.description = description
        self.edition = edition
        self.series = series
        self.caskStrength = caskStrength
        self.singleCask = singleCask
        self.statedAge = statedAge
        self.vintageYear = vintageYear
        self.releaseYear = releaseYear
        self.caskType = caskType
        self.caskSize = caskSize
        self.caskFill = caskFill
        self.distillers = distillers
        self.bottler = bottler
        self.tastingNotes = tastingNotes
        self.suggestedTags = suggestedTags
        self.imageUrl = imageUrl
        self.abv = abv
        self.avgRating = avgRating
        self.ratingStats = ratingStats ?? BottleRatingStats(total: totalRatings, average: avgRating)
        self.totalRatings = ratingStats?.total ?? totalRatings
        self.totalTastings = totalTastings ?? totalRatings
        self.isFavorite = isFavorite
        self.isLibrary = isLibrary
        self.hasTasted = hasTasted
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case fullName
        case brand
        case category
        case description
        case edition
        case series
        case caskStrength
        case singleCask
        case statedAge
        case vintageYear
        case releaseYear
        case caskType
        case caskSize
        case caskFill
        case distillers
        case bottler
        case tastingNotes
        case suggestedTags
        case imageUrl
        case abv
        case avgRating
        case ratingStats
        case totalRatings
        case totalTastings
        case isFavorite
        case isLibrary
        case hasTasted
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        fullName = try container.decode(String.self, forKey: .fullName)
        brand = try container.decode(Brand.self, forKey: .brand)
        category = try container.decodeIfPresent(String.self, forKey: .category)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        edition = try container.decodeIfPresent(String.self, forKey: .edition)
        series = try container.decodeIfPresent(BottleSeriesSummary.self, forKey: .series)
        caskStrength = try container.decodeIfPresent(Bool.self, forKey: .caskStrength) ?? false
        singleCask = try container.decodeIfPresent(Bool.self, forKey: .singleCask) ?? false
        statedAge = try container.decodeIfPresent(Int.self, forKey: .statedAge)
        vintageYear = try container.decodeIfPresent(Int.self, forKey: .vintageYear)
        releaseYear = try container.decodeIfPresent(Int.self, forKey: .releaseYear)
        caskType = try container.decodeIfPresent(String.self, forKey: .caskType)
        caskSize = try container.decodeIfPresent(String.self, forKey: .caskSize)
        caskFill = try container.decodeIfPresent(String.self, forKey: .caskFill)
        distillers = try container.decodeIfPresent([Brand].self, forKey: .distillers) ?? []
        bottler = try container.decodeIfPresent(Brand.self, forKey: .bottler)
        tastingNotes = try container.decodeIfPresent(BottleTastingNotes.self, forKey: .tastingNotes)
        suggestedTags = try container.decodeIfPresent([String].self, forKey: .suggestedTags) ?? []
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        abv = try container.decodeIfPresent(Double.self, forKey: .abv)
        avgRating = try container.decodeIfPresent(Double.self, forKey: .avgRating)

        let legacyTotalRatings = try container.decodeIfPresent(Int.self, forKey: .totalRatings) ?? 0
        ratingStats = try container.decodeIfPresent(BottleRatingStats.self, forKey: .ratingStats)
            ?? BottleRatingStats(total: legacyTotalRatings, average: avgRating)
        totalRatings = ratingStats.total
        totalTastings = try container.decodeIfPresent(Int.self, forKey: .totalTastings) ?? legacyTotalRatings
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        isLibrary = try container.decodeIfPresent(Bool.self, forKey: .isLibrary) ?? false
        hasTasted = try container.decodeIfPresent(Bool.self, forKey: .hasTasted) ?? false
    }
}
