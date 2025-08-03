import Foundation

/// Represents a comment on a tasting
public struct Comment: Identifiable, Codable, Equatable {
  public let id: String
  public let text: String
  public let createdAt: Date
  
  // User info (denormalized for performance)
  public let userId: String
  public let username: String
  public let userDisplayName: String?
  public let userAvatarUrl: String?
  
  // Tasting reference
  public let tastingId: String
  
  /// Creates a new Comment instance
  public init(
    id: String,
    text: String,
    createdAt: Date,
    userId: String,
    username: String,
    userDisplayName: String?,
    userAvatarUrl: String?,
    tastingId: String
  ) {
    self.id = id
    self.text = text
    self.createdAt = createdAt
    self.userId = userId
    self.username = username
    self.userDisplayName = userDisplayName
    self.userAvatarUrl = userAvatarUrl
    self.tastingId = tastingId
  }
  
  /// Display name for the comment author
  public var authorDisplayName: String {
    userDisplayName ?? username
  }
  
  /// Relative time display (e.g., "2 hours ago")
  public var timeAgo: String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    return formatter.localizedString(for: createdAt, relativeTo: Date())
  }
}

// MARK: - API Response Mapping

extension Comment {
  /// Creates a Comment from API response
  public init?(from apiComment: Components.Schemas.Comment?) {
    guard let apiComment = apiComment,
          let id = apiComment.id,
          let text = apiComment.comment,
          let createdAt = apiComment.created_at,
          let createdBy = apiComment.created_by,
          let username = createdBy.username,
          let userId = createdBy.id.map({ String(Int($0)) }),
          let tastingId = apiComment.tasting?.id else {
      return nil
    }
    
    self.init(
      id: String(id),
      text: text,
      createdAt: Date(timeIntervalSince1970: TimeInterval(createdAt)),
      userId: userId,
      username: username,
      userDisplayName: createdBy.display_name,
      userAvatarUrl: createdBy.picture_url,
      tastingId: String(tastingId)
    )
  }
}