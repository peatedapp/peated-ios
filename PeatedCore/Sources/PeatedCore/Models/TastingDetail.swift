import Foundation

/// Represents detailed tasting information including comments and toasts
public struct TastingDetail: Identifiable, Equatable {
  public let id: String
  public let rating: Double
  public let notes: String?
  public let servingStyle: String?
  public let imageUrl: String?
  public let createdAt: Date
  
  // User info
  public let userId: String
  public let username: String
  public let userDisplayName: String?
  public let userAvatarUrl: String?
  
  // Bottle info
  public let bottleId: String
  public let bottleName: String
  public let bottleBrandName: String
  public let bottleCategory: String?
  public let bottleImageUrl: String?
  
  // Social data
  public var toastCount: Int
  public var commentCount: Int
  public var hasToasted: Bool
  
  // Lists
  public let tags: [String]
  public let location: Location?
  public var comments: [Comment]
  public var toasts: [Toast]
  
  public struct Location: Codable, Equatable {
    public let name: String
    public let latitude: Double?
    public let longitude: Double?
  }
  
  public struct Toast: Identifiable, Equatable {
    public let id: String
    public let userId: String
    public let username: String
    public let userDisplayName: String?
    public let userAvatarUrl: String?
    public let createdAt: Date
  }
  
  /// Relative time display
  public var timeAgo: String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    return formatter.localizedString(for: createdAt, relativeTo: Date())
  }
  
  /// Display name for the tasting author
  public var authorDisplayName: String {
    userDisplayName ?? username
  }
}

// MARK: - Conversion from TastingFeedItem

extension TastingDetail {
  /// Creates a TastingDetail from a TastingFeedItem (partial data)
  public init(from feedItem: TastingFeedItem) {
    self.id = feedItem.id
    self.rating = feedItem.rating
    self.notes = feedItem.notes
    self.servingStyle = feedItem.servingStyle
    self.imageUrl = feedItem.imageUrl
    self.createdAt = feedItem.createdAt
    self.userId = feedItem.userId
    self.username = feedItem.username
    self.userDisplayName = feedItem.userDisplayName
    self.userAvatarUrl = feedItem.userAvatarUrl
    self.bottleId = feedItem.bottleId
    self.bottleName = feedItem.bottleName
    self.bottleBrandName = feedItem.bottleBrandName
    self.bottleCategory = feedItem.bottleCategory
    self.bottleImageUrl = feedItem.bottleImageUrl
    self.toastCount = feedItem.toastCount
    self.commentCount = feedItem.commentCount
    self.hasToasted = feedItem.hasToasted
    self.tags = feedItem.tags
    self.location = feedItem.location.map { loc in
      Location(name: loc.name, latitude: loc.latitude, longitude: loc.longitude)
    }
    self.comments = []
    self.toasts = []
  }
}

// MARK: - API Response Mapping

extension TastingDetail {
  /// Creates a TastingDetail from API response
  public init?(from apiTasting: Components.Schemas.Tasting?) {
    guard let apiTasting = apiTasting,
          let id = apiTasting.id,
          let bottle = apiTasting.bottle,
          let bottleName = bottle.name,
          let brand = bottle.brand,
          let brandName = brand?.name,
          let createdBy = apiTasting.created_by,
          let username = createdBy.username,
          let userId = createdBy.id.map({ String(Int($0)) }),
          let createdAt = apiTasting.created_at else {
      return nil
    }
    
    self.init(
      id: String(id),
      rating: apiTasting.rating ?? 0,
      notes: apiTasting.notes,
      servingStyle: apiTasting.serving_style,
      imageUrl: apiTasting.image?.src,
      createdAt: Date(timeIntervalSince1970: TimeInterval(createdAt)),
      userId: userId,
      username: username,
      userDisplayName: createdBy.display_name,
      userAvatarUrl: createdBy.picture_url,
      bottleId: String(bottle.id ?? 0),
      bottleName: bottleName,
      bottleBrandName: brandName,
      bottleCategory: bottle.category,
      bottleImageUrl: bottle.photos?.first?.src,
      toastCount: apiTasting.toasts ?? 0,
      commentCount: apiTasting.comments ?? 0,
      hasToasted: apiTasting.toasted_by_me ?? false,
      tags: apiTasting.tags ?? [],
      location: nil, // TODO: Map location when API provides it
      comments: [], // Will be populated separately
      toasts: [] // Will be populated separately
    )
  }
}