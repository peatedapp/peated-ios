import Foundation

/// Represents an operation that needs to be synced when network connectivity is available
public struct OfflineOperation: Codable, Identifiable, Sendable {
  /// Unique identifier for the operation
  public let id: String
  
  /// Type of operation to be performed
  public let type: OperationType
  
  /// Serialized payload containing operation-specific data
  public let payload: Data
  
  /// When the operation was created
  public let createdAt: Date
  
  /// Number of times this operation has been retried
  public var retryCount: Int
  
  /// Last time we attempted to sync this operation
  public var lastAttemptAt: Date?
  
  /// Current status of the operation
  public var status: OperationStatus
  
  /// Error message from last failed attempt
  public var lastError: String?
  
  /// Types of operations that can be queued for offline sync
  public enum OperationType: String, Codable, CaseIterable, Sendable {
    case createTasting
    case updateTasting
    case deleteTasting
    case toggleToast
    case addComment
    case deleteComment
    case followUser
    case unfollowUser
    case updateProfile
    case uploadImage
    
    /// Human-readable description of the operation type
    public var description: String {
      switch self {
      case .createTasting: return "Create tasting"
      case .updateTasting: return "Update tasting"
      case .deleteTasting: return "Delete tasting"
      case .toggleToast: return "Toast action"
      case .addComment: return "Add comment"
      case .deleteComment: return "Delete comment"
      case .followUser: return "Follow user"
      case .unfollowUser: return "Unfollow user"
      case .updateProfile: return "Update profile"
      case .uploadImage: return "Upload image"
      }
    }
  }
  
  /// Status of the offline operation
  public enum OperationStatus: String, Codable, Sendable {
    case pending
    case inProgress
    case failed
    case completed
  }
  
  /// Creates a new offline operation
  public init(
    type: OperationType,
    payload: Data,
    createdAt: Date = Date()
  ) {
    self.id = UUID().uuidString
    self.type = type
    self.payload = payload
    self.createdAt = createdAt
    self.retryCount = 0
    self.lastAttemptAt = nil
    self.status = .pending
    self.lastError = nil
  }
  
  /// Maximum number of retry attempts before giving up
  public static let maxRetries = 3
  
  /// Operations older than this will be discarded
  public static let maxAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days
  
  /// Checks if this operation has exceeded max retries
  public var hasExceededRetries: Bool {
    retryCount >= Self.maxRetries
  }
  
  /// Checks if this operation is too old to process
  public var isExpired: Bool {
    Date().timeIntervalSince(createdAt) > Self.maxAge
  }
  
  /// Calculates delay for next retry attempt using exponential backoff
  public var nextRetryDelay: TimeInterval {
    let baseDelay: TimeInterval = 2.0 // 2 seconds
    return baseDelay * pow(2.0, Double(retryCount))
  }
}

// MARK: - Operation Payloads

/// Payload for creating a tasting
public struct CreateTastingPayload: Codable, Sendable {
  public let bottleId: String
  public let rating: Double
  public let notes: String?
  public let servingStyle: String?
  public let tags: [String]
  public let imageData: Data?
  public let location: Location?
  
  public struct Location: Codable, Sendable {
    public let name: String
    public let latitude: Double?
    public let longitude: Double?
  }
}

/// Payload for toggling toast
public struct ToggleToastPayload: Codable, Sendable {
  public let tastingId: String
  public let isToasted: Bool
}

/// Payload for adding a comment
public struct AddCommentPayload: Codable, Sendable {
  public let tastingId: String
  public let text: String
}

/// Payload for following/unfollowing user
public struct FollowUserPayload: Codable, Sendable {
  public let userId: String
  public let isFollowing: Bool
}

// MARK: - Helper Extensions

public extension OfflineOperation {
  /// Creates a create tasting operation
  static func createTasting(
    bottleId: String,
    rating: Double,
    notes: String?,
    servingStyle: String?,
    tags: [String],
    imageData: Data?,
    location: CreateTastingPayload.Location?
  ) -> OfflineOperation {
    let payload = CreateTastingPayload(
      bottleId: bottleId,
      rating: rating,
      notes: notes,
      servingStyle: servingStyle,
      tags: tags,
      imageData: imageData,
      location: location
    )
    
    let data = try! JSONEncoder().encode(payload)
    return OfflineOperation(type: .createTasting, payload: data)
  }
  
  /// Creates a toast toggle operation
  static func toggleToast(tastingId: String, isToasted: Bool) -> OfflineOperation {
    let payload = ToggleToastPayload(tastingId: tastingId, isToasted: isToasted)
    let data = try! JSONEncoder().encode(payload)
    return OfflineOperation(type: .toggleToast, payload: data)
  }
  
  /// Creates an add comment operation
  static func addComment(tastingId: String, text: String) -> OfflineOperation {
    let payload = AddCommentPayload(tastingId: tastingId, text: text)
    let data = try! JSONEncoder().encode(payload)
    return OfflineOperation(type: .addComment, payload: data)
  }
  
  /// Creates a follow user operation
  static func followUser(userId: String, isFollowing: Bool) -> OfflineOperation {
    let payload = FollowUserPayload(userId: userId, isFollowing: isFollowing)
    let data = try! JSONEncoder().encode(payload)
    return OfflineOperation(type: isFollowing ? .followUser : .unfollowUser, payload: data)
  }
}