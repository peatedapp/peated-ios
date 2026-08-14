import Foundation

public struct Brand: Codable, Equatable, Sendable {
    public let id: String
    public let name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

public struct Bottle: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let fullName: String
    public let brand: Brand
    public let category: String?
    public let description: String?
    public let caskStrength: Bool
    public let singleCask: Bool
    public let statedAge: Int?

    // Additional properties for UI
    public let imageUrl: String?
    public let abv: Double?
    public let avgRating: Double
    public let totalRatings: Int
    public var isFavorite: Bool
    public var isLibrary: Bool
    public var hasTasted: Bool

    /// Convenience properties
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
        caskStrength: Bool = false,
        singleCask: Bool = false,
        statedAge: Int? = nil,
        imageUrl: String? = nil,
        abv: Double? = nil,
        avgRating: Double = 0.0,
        totalRatings: Int = 0,
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
        self.caskStrength = caskStrength
        self.singleCask = singleCask
        self.statedAge = statedAge
        self.imageUrl = imageUrl
        self.abv = abv
        self.avgRating = avgRating
        self.totalRatings = totalRatings
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
        case caskStrength
        case singleCask
        case statedAge
        case imageUrl
        case abv
        case avgRating
        case totalRatings
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
        caskStrength = try container.decode(Bool.self, forKey: .caskStrength)
        singleCask = try container.decode(Bool.self, forKey: .singleCask)
        statedAge = try container.decodeIfPresent(Int.self, forKey: .statedAge)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        abv = try container.decodeIfPresent(Double.self, forKey: .abv)
        avgRating = try container.decode(Double.self, forKey: .avgRating)
        totalRatings = try container.decode(Int.self, forKey: .totalRatings)
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
        isLibrary = try container.decodeIfPresent(Bool.self, forKey: .isLibrary) ?? false
        hasTasted = try container.decodeIfPresent(Bool.self, forKey: .hasTasted) ?? false
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(fullName, forKey: .fullName)
        try container.encode(brand, forKey: .brand)
        try container.encodeIfPresent(category, forKey: .category)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encode(caskStrength, forKey: .caskStrength)
        try container.encode(singleCask, forKey: .singleCask)
        try container.encodeIfPresent(statedAge, forKey: .statedAge)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encodeIfPresent(abv, forKey: .abv)
        try container.encode(avgRating, forKey: .avgRating)
        try container.encode(totalRatings, forKey: .totalRatings)
        try container.encode(isFavorite, forKey: .isFavorite)
        try container.encode(isLibrary, forKey: .isLibrary)
        try container.encode(hasTasted, forKey: .hasTasted)
    }
}
