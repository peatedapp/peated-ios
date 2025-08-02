import Foundation

public struct Brand: Codable, Equatable, Sendable {
  public let id: String
  public let name: String
  
  public init(id: String, name: String) {
    self.id = id
    self.name = name
  }
}

public struct Bottle: Codable, Equatable, Sendable {
  public let id: String
  public let name: String
  public let fullName: String
  public let brand: Brand
  public let category: String?
  public let caskStrength: Bool
  public let singleCask: Bool
  public let statedAge: Int?
  
  public init(
    id: String,
    name: String,
    fullName: String,
    brand: Brand,
    category: String? = nil,
    caskStrength: Bool = false,
    singleCask: Bool = false,
    statedAge: Int? = nil
  ) {
    self.id = id
    self.name = name
    self.fullName = fullName
    self.brand = brand
    self.category = category
    self.caskStrength = caskStrength
    self.singleCask = singleCask
    self.statedAge = statedAge
  }
}