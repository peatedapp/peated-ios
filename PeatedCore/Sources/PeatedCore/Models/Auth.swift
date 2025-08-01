import Foundation

public struct User: Codable, Equatable, Sendable {
  public let id: String
  public let email: String
  public let username: String
  public let verified: Bool
  public let admin: Bool
  public let mod: Bool
  
  // Profile data
  public var pictureUrl: String?
  
  // Profile statistics (will be populated separately)
  public var tastingsCount: Int = 0
  public var bottlesCount: Int = 0
  public var collectedCount: Int = 0
  public var contributionsCount: Int = 0
  
  public init(id: String, email: String, username: String, verified: Bool = false, admin: Bool = false, mod: Bool = false) {
    self.id = id
    self.email = email
    self.username = username
    self.verified = verified
    self.admin = admin
    self.mod = mod
  }
  
  public init(id: Double, email: String?, username: String, verified: Bool? = false, admin: Bool? = false, mod: Bool? = false) {
    self.id = String(Int(id))
    self.email = email ?? ""
    self.username = username
    self.verified = verified ?? false
    self.admin = admin ?? false
    self.mod = mod ?? false
  }
}

// Achievement/Badge model
public struct Achievement: Codable, Equatable, Sendable, Identifiable {
  public let id: String
  public let name: String
  public let level: Int
  public let imageUrl: String?
  public let unlockedAt: Date?
  
  public init(id: String, name: String, level: Int, imageUrl: String? = nil, unlockedAt: Date? = nil) {
    self.id = id
    self.name = name
    self.level = level
    self.imageUrl = imageUrl
    self.unlockedAt = unlockedAt
  }
}

public enum AuthState: Equatable, Sendable {
  case unknown
  case authenticated(User)
  case unauthenticated
}