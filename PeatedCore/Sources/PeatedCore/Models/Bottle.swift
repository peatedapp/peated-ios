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

public struct RatingBandCounts: Codable, Equatable, Sendable {
    public let mediocre: Int
    public let good: Int
    public let veryGood: Int
    public let outstanding: Int
    public let unicorn: Int

    public init(
        mediocre: Int = 0,
        good: Int = 0,
        veryGood: Int = 0,
        outstanding: Int = 0,
        unicorn: Int = 0
    ) {
        self.mediocre = mediocre
        self.good = good
        self.veryGood = veryGood
        self.outstanding = outstanding
        self.unicorn = unicorn
    }

    public var total: Int {
        mediocre + good + veryGood + outstanding + unicorn
    }

    public func count(for band: TastingRatingBand) -> Int {
        switch band {
        case .mediocre: mediocre
        case .good: good
        case .veryGood: veryGood
        case .outstanding: outstanding
        case .unicorn: unicorn
        }
    }

    public var lowerMedianBand: TastingRatingBand? {
        guard total > 0 else { return nil }

        let medianIndex = (total - 1) / 2
        var cumulativeCount = 0
        for band in TastingRatingBand.allCases {
            cumulativeCount += count(for: band)
            if medianIndex < cumulativeCount {
                return band
            }
        }
        return nil
    }
}

public struct BottleRatingSummary: Codable, Equatable, Sendable {
    public let medianScore: Int?
    public let minimumScore: Int?
    public let maximumScore: Int?
    public let memberScoreCount: Int
    public let externalScoreCount: Int
    public let reviewBandCounts: RatingBandCounts
    public let tastingBandCounts: RatingBandCounts

    public init(
        medianScore: Int? = nil,
        minimumScore: Int? = nil,
        maximumScore: Int? = nil,
        memberScoreCount: Int = 0,
        externalScoreCount: Int = 0,
        reviewBandCounts: RatingBandCounts = RatingBandCounts(),
        tastingBandCounts: RatingBandCounts = RatingBandCounts()
    ) {
        self.medianScore = medianScore
        self.minimumScore = minimumScore
        self.maximumScore = maximumScore
        self.memberScoreCount = memberScoreCount
        self.externalScoreCount = externalScoreCount
        self.reviewBandCounts = reviewBandCounts
        self.tastingBandCounts = tastingBandCounts
    }

    public var scoreCount: Int {
        memberScoreCount + externalScoreCount
    }

    public var presentedBand: TastingRatingBand? {
        if let medianScore {
            return TastingRatingBand(score: medianScore)
        }
        return tastingBandCounts.lowerMedianBand
    }

    public var presentedCount: Int {
        medianScore == nil ? tastingBandCounts.total : scoreCount
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
    public let bottlingYear: Int?
    public let releaseYear: Int?
    public let releaseMonth: Int?
    public let releaseDay: Int?
    public let caskNumber: String?
    public let maturation: String?
    public let maltPhenolPpm: Double?
    public let naturalColor: Bool?
    public let nonChillFiltered: Bool?
    public let noAgeStatement: Bool?
    public let outturn: Int?
    public let distillers: [Brand]
    public let bottler: Brand?
    public let tastingNotes: BottleTastingNotes?
    public let suggestedTags: [String]

    // Additional properties for UI
    public let imageUrl: String?
    public let abv: Double?
    public let ratingSummary: BottleRatingSummary
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
        bottlingYear: Int? = nil,
        releaseYear: Int? = nil,
        releaseMonth: Int? = nil,
        releaseDay: Int? = nil,
        caskNumber: String? = nil,
        maturation: String? = nil,
        maltPhenolPpm: Double? = nil,
        naturalColor: Bool? = nil,
        nonChillFiltered: Bool? = nil,
        noAgeStatement: Bool? = nil,
        outturn: Int? = nil,
        distillers: [Brand] = [],
        bottler: Brand? = nil,
        tastingNotes: BottleTastingNotes? = nil,
        suggestedTags: [String] = [],
        imageUrl: String? = nil,
        abv: Double? = nil,
        ratingSummary: BottleRatingSummary = BottleRatingSummary(),
        totalTastings: Int = 0,
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
        self.bottlingYear = bottlingYear
        self.releaseYear = releaseYear
        self.releaseMonth = releaseMonth
        self.releaseDay = releaseDay
        self.caskNumber = caskNumber
        self.maturation = maturation
        self.maltPhenolPpm = maltPhenolPpm
        self.naturalColor = naturalColor
        self.nonChillFiltered = nonChillFiltered
        self.noAgeStatement = noAgeStatement
        self.outturn = outturn
        self.distillers = distillers
        self.bottler = bottler
        self.tastingNotes = tastingNotes
        self.suggestedTags = suggestedTags
        self.imageUrl = imageUrl
        self.abv = abv
        self.ratingSummary = ratingSummary
        self.totalTastings = totalTastings
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
        case bottlingYear
        case releaseYear
        case releaseMonth
        case releaseDay
        case caskNumber
        case maturation
        case maltPhenolPpm
        case naturalColor
        case nonChillFiltered
        case noAgeStatement
        case outturn
        case distillers
        case bottler
        case tastingNotes
        case suggestedTags
        case imageUrl
        case abv
        case ratingSummary
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
        bottlingYear = try container.decodeIfPresent(Int.self, forKey: .bottlingYear)
        releaseYear = try container.decodeIfPresent(Int.self, forKey: .releaseYear)
        releaseMonth = try container.decodeIfPresent(Int.self, forKey: .releaseMonth)
        releaseDay = try container.decodeIfPresent(Int.self, forKey: .releaseDay)
        caskNumber = try container.decodeIfPresent(String.self, forKey: .caskNumber)
        maturation = try container.decodeIfPresent(String.self, forKey: .maturation)
        maltPhenolPpm = try container.decodeIfPresent(Double.self, forKey: .maltPhenolPpm)
        naturalColor = try container.decodeIfPresent(Bool.self, forKey: .naturalColor)
        nonChillFiltered = try container.decodeIfPresent(Bool.self, forKey: .nonChillFiltered)
        noAgeStatement = try container.decodeIfPresent(Bool.self, forKey: .noAgeStatement)
        outturn = try container.decodeIfPresent(Int.self, forKey: .outturn)
        distillers = try container.decodeIfPresent([Brand].self, forKey: .distillers) ?? []
        bottler = try container.decodeIfPresent(Brand.self, forKey: .bottler)
        tastingNotes = try container.decodeIfPresent(BottleTastingNotes.self, forKey: .tastingNotes)
        suggestedTags = try container.decodeIfPresent([String].self, forKey: .suggestedTags) ?? []
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        abv = try container.decodeIfPresent(Double.self, forKey: .abv)
        ratingSummary = try container.decodeIfPresent(BottleRatingSummary.self, forKey: .ratingSummary)
            ?? BottleRatingSummary()
        totalTastings = try container.decodeIfPresent(Int.self, forKey: .totalTastings) ?? 0
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        isLibrary = try container.decodeIfPresent(Bool.self, forKey: .isLibrary) ?? false
        hasTasted = try container.decodeIfPresent(Bool.self, forKey: .hasTasted) ?? false
    }
}
