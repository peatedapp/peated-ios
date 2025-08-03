import Foundation
import SQLite

/// Manages offline operations that need to be synced when network is available
@Observable
@MainActor
public class OfflineQueueManager {
  /// Shared singleton instance
  public static let shared = OfflineQueueManager()
  
  /// Currently pending operations
  public private(set) var pendingOperations: [OfflineOperation] = []
  
  /// Whether the queue is currently syncing
  public private(set) var isSyncing = false
  
  /// Number of operations currently in the queue
  public var pendingCount: Int {
    pendingOperations.count
  }
  
  /// Number of failed operations
  public var failedCount: Int {
    pendingOperations.filter { $0.status == .failed }.count
  }
  
  // Private properties
  private let database: DatabaseManager
  private let tastingRepository: TastingRepository
  private let userRepository: UserRepository
  private var syncTask: Task<Void, Never>?
  
  /// Private initializer to enforce singleton pattern
  private init() {
    self.database = DatabaseManager.shared
    
    // Create repositories with shared API client
    let apiClient = APIClient(serverURL: URL(string: "https://api.peated.com/v1")!)
    self.tastingRepository = TastingRepository(apiClient: apiClient)
    self.userRepository = UserRepository(apiClient: apiClient)
    
    // Load pending operations from database
    Task {
      await loadPendingOperations()
    }
  }
  
  /// Loads pending operations from the database
  private func loadPendingOperations() async {
    do {
      pendingOperations = try await database.getPendingOperations()
      print("OfflineQueueManager: Loaded \(pendingOperations.count) pending operations")
    } catch {
      print("OfflineQueueManager: Failed to load pending operations: \(error)")
    }
  }
  
  /// Queues an operation for offline sync
  public func queueOperation(_ operation: OfflineOperation) async {
    // Save to database for persistence
    do {
      try await database.saveOfflineOperation(operation)
      pendingOperations.append(operation)
      
      print("OfflineQueueManager: Queued operation \(operation.type.description)")
      
      // Try to execute immediately if online
      if NetworkMonitor.shared.isConnected {
        await processPendingOperations()
      }
    } catch {
      print("OfflineQueueManager: Failed to queue operation: \(error)")
    }
  }
  
  /// Processes all pending operations
  public func processPendingOperations() async {
    // Avoid concurrent sync operations
    guard !isSyncing && NetworkMonitor.shared.isConnected else {
      print("OfflineQueueManager: Skipping sync - already syncing or offline")
      return
    }
    
    // Cancel any existing sync task
    syncTask?.cancel()
    
    // Start new sync task
    syncTask = Task {
      await performSync()
    }
    
    await syncTask?.value
  }
  
  /// Performs the actual sync operation
  private func performSync() async {
    isSyncing = true
    defer { isSyncing = false }
    
    print("OfflineQueueManager: Starting sync of \(pendingOperations.count) operations")
    
    // Filter out expired and failed operations
    let operationsToProcess = pendingOperations.filter { operation in
      !operation.isExpired && !operation.hasExceededRetries && operation.status != .completed
    }
    
    for operation in operationsToProcess {
      // Check for task cancellation
      if Task.isCancelled {
        print("OfflineQueueManager: Sync cancelled")
        break
      }
      
      // Skip if we're offline
      guard NetworkMonitor.shared.isConnected else {
        print("OfflineQueueManager: Lost connectivity, stopping sync")
        break
      }
      
      await processOperation(operation)
    }
    
    // Clean up completed and expired operations
    await cleanupOperations()
  }
  
  /// Processes a single operation
  private func processOperation(_ operation: OfflineOperation) async {
    print("OfflineQueueManager: Processing operation \(operation.id) of type \(operation.type)")
    
    // Update status to in progress
    var updatedOperation = operation
    updatedOperation.status = .inProgress
    updatedOperation.lastAttemptAt = Date()
    
    // Update in memory and database
    if let index = pendingOperations.firstIndex(where: { $0.id == operation.id }) {
      pendingOperations[index] = updatedOperation
    }
    
    do {
      // Execute the operation based on type
      try await executeOperation(operation)
      
      // Mark as completed
      updatedOperation.status = .completed
      
      // Update in memory and database
      if let index = pendingOperations.firstIndex(where: { $0.id == operation.id }) {
        pendingOperations[index] = updatedOperation
      }
      
      try await database.updateOfflineOperation(updatedOperation)
      
      // Show success notification
      ToastManager.shared.showSuccess("\(operation.type.description) synced")
      
      print("OfflineQueueManager: Successfully processed operation \(operation.id)")
      
    } catch {
      // Handle failure
      updatedOperation.status = .failed
      updatedOperation.retryCount += 1
      updatedOperation.lastError = error.localizedDescription
      
      // Update in memory and database
      if let index = pendingOperations.firstIndex(where: { $0.id == operation.id }) {
        pendingOperations[index] = updatedOperation
      }
      
      try? await database.updateOfflineOperation(updatedOperation)
      
      print("OfflineQueueManager: Failed to process operation \(operation.id): \(error)")
      
      // Show error for final failure
      if updatedOperation.hasExceededRetries {
        ToastManager.shared.showError("Failed to sync \(operation.type.description)")
      }
      
      // Apply exponential backoff for retry
      if !updatedOperation.hasExceededRetries {
        let delay = updatedOperation.nextRetryDelay
        print("OfflineQueueManager: Will retry operation \(operation.id) after \(delay) seconds")
        
        Task {
          try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
          if NetworkMonitor.shared.isConnected {
            await processOperation(updatedOperation)
          }
        }
      }
    }
  }
  
  /// Executes the actual API call for an operation
  private func executeOperation(_ operation: OfflineOperation) async throws {
    switch operation.type {
    case .createTasting:
      let payload = try JSONDecoder().decode(CreateTastingPayload.self, from: operation.payload)
      let input = CreateTastingInput(
        bottleId: payload.bottleId,
        rating: payload.rating,
        notes: payload.notes,
        servingStyle: payload.servingStyle,
        tags: payload.tags,
        location: payload.location?.name
      )
      _ = try await tastingRepository.createTasting(input)
      
    case .toggleToast:
      let payload = try JSONDecoder().decode(ToggleToastPayload.self, from: operation.payload)
      _ = try await tastingRepository.toggleToast(tastingId: payload.tastingId)
      
    case .addComment:
      let payload = try JSONDecoder().decode(AddCommentPayload.self, from: operation.payload)
      // TODO: Implement when comment API is available
      throw OfflineQueueError.notImplemented
      
    case .followUser, .unfollowUser:
      let payload = try JSONDecoder().decode(FollowUserPayload.self, from: operation.payload)
      if operation.type == .followUser {
        try await userRepository.followUser(id: payload.userId)
      } else {
        try await userRepository.unfollowUser(id: payload.userId)
      }
      
    case .updateTasting, .deleteTasting, .deleteComment, .updateProfile, .uploadImage:
      // TODO: Implement when APIs are available
      throw OfflineQueueError.notImplemented
    }
  }
  
  /// Cleans up completed and expired operations
  private func cleanupOperations() async {
    let beforeCount = pendingOperations.count
    
    // Remove completed operations
    pendingOperations.removeAll { $0.status == .completed }
    
    // Remove expired operations
    let expiredOperations = pendingOperations.filter { $0.isExpired }
    for expired in expiredOperations {
      print("OfflineQueueManager: Removing expired operation \(expired.id)")
      try? await database.deleteOfflineOperation(expired.id)
    }
    pendingOperations.removeAll { $0.isExpired }
    
    let removedCount = beforeCount - pendingOperations.count
    if removedCount > 0 {
      print("OfflineQueueManager: Cleaned up \(removedCount) operations")
    }
  }
  
  /// Retries all failed operations
  public func retryFailedOperations() async {
    let failedOperations = pendingOperations.filter { 
      $0.status == .failed && !$0.hasExceededRetries 
    }
    
    guard !failedOperations.isEmpty else { return }
    
    print("OfflineQueueManager: Retrying \(failedOperations.count) failed operations")
    
    // Reset retry count for user-initiated retry
    for var operation in failedOperations {
      operation.retryCount = 0
      operation.status = .pending
      
      if let index = pendingOperations.firstIndex(where: { $0.id == operation.id }) {
        pendingOperations[index] = operation
      }
    }
    
    await processPendingOperations()
  }
  
  /// Clears all pending operations (use with caution)
  public func clearAllOperations() async {
    pendingOperations.removeAll()
    try? await database.deleteAllOfflineOperations()
    print("OfflineQueueManager: Cleared all operations")
  }
  
  /// Gets a summary of pending operations by type
  public var operationsSummary: [OfflineOperation.OperationType: Int] {
    Dictionary(grouping: pendingOperations, by: { $0.type })
      .mapValues { $0.count }
  }
}

// MARK: - Errors

enum OfflineQueueError: LocalizedError {
  case notImplemented
  case networkUnavailable
  case operationExpired
  
  var errorDescription: String? {
    switch self {
    case .notImplemented:
      return "This operation is not yet implemented"
    case .networkUnavailable:
      return "Network is not available"
    case .operationExpired:
      return "Operation has expired"
    }
  }
}