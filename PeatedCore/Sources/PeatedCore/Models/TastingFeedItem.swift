import Foundation

public struct TastingFeedItem: Identifiable, Equatable, Sendable {
  public let id: String
  public let rating: Double
  public let notes: String?
  public let servingStyle: String?
  public let imageUrl: String?
  public let createdAt: Date
  
  // User info (denormalized)
  public let userId: String
  public let username: String
  public let userDisplayName: String?
  public let userAvatarUrl: String?
  
  // Bottle info (denormalized)
  public let bottleId: String
  public let bottleName: String
  public let bottleBrandName: String
  public let bottleCategory: String?
  public let bottleImageUrl: String?
  
  // Social
  public let toastCount: Int
  public let commentCount: Int
  public let hasToasted: Bool
  
  // Additional info
  public let tags: [String]
  public let location: String?
  public let friendUsernames: [String]
  
  public init(
    id: String,
    rating: Double,
    notes: String?,
    servingStyle: String?,
    imageUrl: String?,
    createdAt: Date,
    userId: String,
    username: String,
    userDisplayName: String?,
    userAvatarUrl: String?,
    bottleId: String,
    bottleName: String,
    bottleBrandName: String,
    bottleCategory: String?,
    bottleImageUrl: String?,
    toastCount: Int,
    commentCount: Int,
    hasToasted: Bool,
    tags: [String],
    location: String?,
    friendUsernames: [String]
  ) {
    self.id = id
    self.rating = rating
    self.notes = notes
    self.servingStyle = servingStyle
    self.imageUrl = imageUrl
    self.createdAt = createdAt
    self.userId = userId
    self.username = username
    self.userDisplayName = userDisplayName
    self.userAvatarUrl = userAvatarUrl
    self.bottleId = bottleId
    self.bottleName = bottleName
    self.bottleBrandName = bottleBrandName
    self.bottleCategory = bottleCategory
    self.bottleImageUrl = bottleImageUrl
    self.toastCount = toastCount
    self.commentCount = commentCount
    self.hasToasted = hasToasted
    self.tags = tags
    self.location = location
    self.friendUsernames = friendUsernames
  }
  
  public var displayUsername: String {
    userDisplayName ?? username
  }
  
  public var timeAgo: String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    return formatter.localizedString(for: createdAt, relativeTo: Date())
  }
}