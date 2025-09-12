import Foundation

public enum SearchResultType: String, Codable, Sendable, CaseIterable {
  case bottle
  case entity
  case user
}

public struct SearchResult: Identifiable, Equatable, Sendable {
  public let id: String
  public let type: SearchResultType
  public let name: String
  public let subtitle: String?
  public let imageUrl: String?
  public let rating: Double?
  public let ratingCount: Int?
  public let isFollowing: Bool?
  public let bottle: Bottle?

  public init(
    id: String,
    type: SearchResultType,
    name: String,
    subtitle: String? = nil,
    imageUrl: String? = nil,
    rating: Double? = nil,
    ratingCount: Int? = nil,
    isFollowing: Bool? = nil,
    bottle: Bottle? = nil
  ) {
    self.id = id
    self.type = type
    self.name = name
    self.subtitle = subtitle
    self.imageUrl = imageUrl
    self.rating = rating
    self.ratingCount = ratingCount
    self.isFollowing = isFollowing
    self.bottle = bottle
  }
}

extension SearchResultType {
  public var sectionTitle: String {
    switch self {
    case .bottle: return "BOTTLES"
    case .entity: return "BRANDS & DISTILLERIES"
    case .user: return "USERS"
    }
  }
}
