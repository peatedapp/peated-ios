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
  public let caskStrength: Bool
  public let singleCask: Bool
  public let statedAge: Int?
  
  // Additional properties for UI
  public let imageUrl: String?
  public let abv: Double?
  public let avgRating: Double
  public let totalRatings: Int
  
  // Convenience properties
  public var brandName: String { brand.name }
  
  public init(
    id: String,
    name: String,
    fullName: String,
    brand: Brand,
    category: String? = nil,
    caskStrength: Bool = false,
    singleCask: Bool = false,
    statedAge: Int? = nil,
    imageUrl: String? = nil,
    abv: Double? = nil,
    avgRating: Double = 0.0,
    totalRatings: Int = 0
  ) {
    self.id = id
    self.name = name
    self.fullName = fullName
    self.brand = brand
    self.category = category
    self.caskStrength = caskStrength
    self.singleCask = singleCask
    self.statedAge = statedAge
    self.imageUrl = imageUrl
    self.abv = abv
    self.avgRating = avgRating
    self.totalRatings = totalRatings
  }
}