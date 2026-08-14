import Foundation

/// Entity represents a brand, distillery, or bottler
public struct Entity: Codable, Equatable, Sendable, Identifiable {
    public let id: String
    public let name: String
    public let type: EntityType
    public let description: String?
    public let imageUrl: String?
    public let country: String?
    public let region: String?
    public let totalBottles: Int
    public let totalTastings: Int

    public enum EntityType: String, Codable, Sendable {
        case brand
        case distillery
        case bottler

        public var displayName: String {
            switch self {
            case .brand: "Brand"
            case .distillery: "Distillery"
            case .bottler: "Bottler"
            }
        }
    }

    public init(
        id: String,
        name: String,
        type: EntityType,
        description: String? = nil,
        imageUrl: String? = nil,
        country: String? = nil,
        region: String? = nil,
        totalBottles: Int = 0,
        totalTastings: Int = 0
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.description = description
        self.imageUrl = imageUrl
        self.country = country
        self.region = region
        self.totalBottles = totalBottles
        self.totalTastings = totalTastings
    }
}
