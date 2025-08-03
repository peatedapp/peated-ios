import Foundation
import PeatedAPI

/// Model for managing tasting detail view state and data
@Observable
@MainActor
public class TastingDetailModel {
  // State
  public enum ViewState: Equatable {
    case loading
    case loaded(TastingDetail)
    case error(String)
  }
  
  public enum CommentState: Equatable {
    case loading
    case loaded([Comment])
    case error(String)
  }
  
  public private(set) var state: ViewState = .loading
  public private(set) var commentState: CommentState = .loading
  public private(set) var isPostingComment = false
  public private(set) var isDeletingComment = false
  
  // Data
  public var tasting: TastingDetail? {
    if case .loaded(let detail) = state {
      return detail
    }
    return nil
  }
  
  // Dependencies
  private let tastingId: String
  private let tastingRepository: TastingRepository
  private let apiClient: APIClient
  
  public init(
    tastingId: String,
    tastingRepository: TastingRepository? = nil
  ) {
    self.tastingId = tastingId
    
    // Create API client
    let apiClient = APIClient(
      serverURL: URL(string: "https://api.peated.com/v1")!
    )
    self.apiClient = apiClient
    self.tastingRepository = tastingRepository ?? TastingRepository(apiClient: apiClient)
  }
  
  /// Loads the full tasting details including comments
  public func loadTasting() async {
    state = .loading
    
    do {
      // Get tasting details
      let client = await apiClient.generatedClient
      let response = try await client.getTasting(
        .init(
          path: .init(tasting: Double(tastingId) ?? 0)
        )
      )
      
      guard case .ok(let okResponse) = response,
            case .json(let payload) = okResponse.body else {
        state = .error("Failed to load tasting")
        return
      }
      
      // Map the API response to TastingDetail
      let detail = TastingDetail(
        id: String(Int(payload.id)),
        rating: payload.rating ?? 0.0,
        notes: payload.notes,
        servingStyle: payload.servingStyle?.value as? String,
        imageUrl: payload.imageUrl,
        createdAt: payload.createdAt,
        userId: String(Int(payload.createdBy.id)),
        username: payload.createdBy.username,
        userDisplayName: nil, // API doesn't provide display name separately
        userAvatarUrl: payload.createdBy.pictureUrl,
        bottleId: String(Int(payload.bottle.id)),
        bottleName: payload.bottle.fullName,
        bottleBrandName: payload.bottle.brand.name,
        bottleCategory: payload.bottle.category?.value as? String,
        bottleImageUrl: payload.bottle.imageUrl,
        toastCount: Int(payload.toasts),
        commentCount: Int(payload.comments),
        hasToasted: payload.hasToasted ?? false,
        tags: payload.tags ?? [],
        location: nil, // TODO: location field needs to be added to API response
        comments: [], // Comments loaded separately
        toasts: []
      )
      
      state = .loaded(detail)
      
      // Load comments separately with error handling
      await loadComments()
      
    } catch {
      state = .error(error.localizedDescription)
    }
  }
  
  /// Loads comments for the tasting
  public func loadComments() async {
    print("TastingDetailModel: Loading comments for tasting \(tastingId)")
    commentState = .loading
    
    do {
      // Use the actual listComments API endpoint
      let client = await apiClient.generatedClient
      print("TastingDetailModel: Making API call to listComments with tasting ID: \(tastingId)")
      let response = try await client.listComments(
        .init(
          query: .init(
            tasting: Double(tastingId) ?? 0,
            limit: 100 // Load up to 100 comments
          )
        )
      )
      
      guard case .ok(let okResponse) = response,
            case .json(let payload) = okResponse.body else {
        print("TastingDetailModel: Invalid response from listComments API")
        commentState = .error("Failed to load comments")
        return
      }
      
      print("TastingDetailModel: Successfully got \(payload.results.count) comments from API")
      
      // Map API comments to our Comment model
      let comments = payload.results.map { apiComment in
        Comment(
          id: String(Int(apiComment.id)),
          text: apiComment.comment,
          createdAt: apiComment.createdAt,
          userId: String(Int(apiComment.createdBy.id)),
          username: apiComment.createdBy.username,
          userDisplayName: nil, // API doesn't provide separate display name
          userAvatarUrl: apiComment.createdBy.pictureUrl,
          tastingId: tastingId
        )
      }
      
      commentState = .loaded(comments)
      
      // Update the tasting detail with comments if loaded
      if case .loaded(var detail) = state {
        detail.comments = comments
        detail.commentCount = comments.count
        state = .loaded(detail)
      }
      
    } catch {
      print("TastingDetailModel: Failed to load comments for tasting \(tastingId): \(error)")
      commentState = .error("Failed to load comments")
      // Don't fail the whole view, just show error for comments
    }
  }
  
  /// Toggles the toast state for the current tasting
  public func toggleToast() async {
    guard var detail = tasting else { return }
    
    // Optimistic update
    let newToastedState = !detail.hasToasted
    detail.hasToasted = newToastedState
    detail.toastCount += newToastedState ? 1 : -1
    state = .loaded(detail)
    
    // Check network status for offline support
    if !NetworkMonitor.shared.isConnected {
      let operation = OfflineOperation.toggleToast(
        tastingId: tastingId,
        isToasted: newToastedState
      )
      await OfflineQueueManager.shared.queueOperation(operation)
      ToastManager.shared.showInfo("Toast will sync when online")
      return
    }
    
    // Perform API call
    do {
      let actualToastedState = try await tastingRepository.toggleToast(tastingId: tastingId)
      
      // Update with actual state
      detail.hasToasted = actualToastedState
      detail.toastCount = detail.toastCount + (actualToastedState ? 0 : -1)
      state = .loaded(detail)
      
      if actualToastedState {
        ToastManager.shared.showSuccess("Cheers! 🥃")
      }
      
    } catch {
      // Revert on error
      detail.hasToasted = !newToastedState
      detail.toastCount += newToastedState ? -1 : 1
      state = .loaded(detail)
      
      ToastManager.shared.showError("Failed to update toast")
    }
  }
  
  /// Posts a new comment on the tasting
  public func postComment(_ text: String) async {
    guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
    guard var detail = tasting else { return }
    
    isPostingComment = true
    defer { isPostingComment = false }
    
    // Check network status for offline support
    if !NetworkMonitor.shared.isConnected {
      let operation = OfflineOperation.addComment(
        tastingId: tastingId,
        text: text
      )
      await OfflineQueueManager.shared.queueOperation(operation)
      ToastManager.shared.showInfo("Comment will post when online")
      return
    }
    
    // TODO: Implement when createComment API is available
    ToastManager.shared.showInfo("Comment posting not yet implemented")
  }
  
  /// Deletes a comment
  public func deleteComment(_ comment: Comment) async {
    guard var detail = tasting else { return }
    
    isDeletingComment = true
    defer { isDeletingComment = false }
    
    // Optimistic removal
    detail.comments.removeAll { $0.id == comment.id }
    detail.commentCount = max(0, detail.commentCount - 1)
    state = .loaded(detail)
    
    // TODO: Implement when deleteComment API is available
    ToastManager.shared.showInfo("Comment deletion not yet implemented")
  }
  
  /// Deletes the tasting
  public func deleteTasting() async throws {
    // TODO: Implement when deleteTasting API is available
    throw APIError.notImplemented
  }
  
  /// Refreshes the tasting data
  public func refresh() async {
    await loadTasting()
  }
}