import Foundation
import SQLite

// MARK: - Offline Operations Management

extension DatabaseManager {
  /// Saves an offline operation to the database
  public func saveOfflineOperation(_ operation: OfflineOperation) async throws {
    let insert = Tables.offlineOperations.insert(
      Tables.OfflineOperations.id <- operation.id,
      Tables.OfflineOperations.type <- operation.type.rawValue,
      Tables.OfflineOperations.payload <- operation.payload,
      Tables.OfflineOperations.createdAt <- operation.createdAt,
      Tables.OfflineOperations.retryCount <- operation.retryCount,
      Tables.OfflineOperations.lastAttemptAt <- operation.lastAttemptAt,
      Tables.OfflineOperations.status <- operation.status.rawValue,
      Tables.OfflineOperations.lastError <- operation.lastError
    )
    
    try connection.run(insert)
  }
  
  /// Updates an existing offline operation
  public func updateOfflineOperation(_ operation: OfflineOperation) async throws {
    let operationRow = Tables.offlineOperations.filter(Tables.OfflineOperations.id == operation.id)
    
    let update = operationRow.update(
      Tables.OfflineOperations.retryCount <- operation.retryCount,
      Tables.OfflineOperations.lastAttemptAt <- operation.lastAttemptAt,
      Tables.OfflineOperations.status <- operation.status.rawValue,
      Tables.OfflineOperations.lastError <- operation.lastError
    )
    
    try connection.run(update)
  }
  
  /// Deletes an offline operation by ID
  public func deleteOfflineOperation(_ id: String) async throws {
    let operation = Tables.offlineOperations.filter(Tables.OfflineOperations.id == id)
    try connection.run(operation.delete())
  }
  
  /// Deletes all offline operations
  public func deleteAllOfflineOperations() async throws {
    try connection.run(Tables.offlineOperations.delete())
  }
  
  /// Gets all pending operations
  public func getPendingOperations() async throws -> [OfflineOperation] {
    let query = Tables.offlineOperations
      .filter(Tables.OfflineOperations.status != OfflineOperation.OperationStatus.completed.rawValue)
      .order(Tables.OfflineOperations.createdAt.asc)
    
    let rows = try connection.prepare(query)
    
    return try rows.map { row in
      OfflineOperation(
        id: row[Tables.OfflineOperations.id],
        type: OfflineOperation.OperationType(rawValue: row[Tables.OfflineOperations.type])!,
        payload: row[Tables.OfflineOperations.payload],
        createdAt: row[Tables.OfflineOperations.createdAt],
        retryCount: row[Tables.OfflineOperations.retryCount],
        lastAttemptAt: row[Tables.OfflineOperations.lastAttemptAt],
        status: OfflineOperation.OperationStatus(rawValue: row[Tables.OfflineOperations.status])!,
        lastError: row[Tables.OfflineOperations.lastError]
      )
    }
  }
  
  /// Gets operations by status
  public func getOperationsByStatus(_ status: OfflineOperation.OperationStatus) async throws -> [OfflineOperation] {
    let query = Tables.offlineOperations
      .filter(Tables.OfflineOperations.status == status.rawValue)
      .order(Tables.OfflineOperations.createdAt.asc)
    
    let rows = try connection.prepare(query)
    
    return try rows.map { row in
      OfflineOperation(
        id: row[Tables.OfflineOperations.id],
        type: OfflineOperation.OperationType(rawValue: row[Tables.OfflineOperations.type])!,
        payload: row[Tables.OfflineOperations.payload],
        createdAt: row[Tables.OfflineOperations.createdAt],
        retryCount: row[Tables.OfflineOperations.retryCount],
        lastAttemptAt: row[Tables.OfflineOperations.lastAttemptAt],
        status: OfflineOperation.OperationStatus(rawValue: row[Tables.OfflineOperations.status])!,
        lastError: row[Tables.OfflineOperations.lastError]
      )
    }
  }
  
  /// Counts operations by status
  public func countOperationsByStatus(_ status: OfflineOperation.OperationStatus) async throws -> Int {
    let count = try connection.scalar(
      Tables.offlineOperations
        .filter(Tables.OfflineOperations.status == status.rawValue)
        .count
    )
    return count
  }
  
  /// Marks operations as failed that have exceeded retry count
  public func markExpiredOperationsFailed() async throws {
    let expiredDate = Date().addingTimeInterval(-OfflineOperation.maxAge)
    
    let update = Tables.offlineOperations
      .filter(Tables.OfflineOperations.createdAt < expiredDate)
      .filter(Tables.OfflineOperations.status != OfflineOperation.OperationStatus.completed.rawValue)
      .update(
        Tables.OfflineOperations.status <- OfflineOperation.OperationStatus.failed.rawValue,
        Tables.OfflineOperations.lastError <- "Operation expired"
      )
    
    try connection.run(update)
  }
}

// MARK: - OfflineOperation Extension

extension OfflineOperation {
  /// Creates an OfflineOperation from a database row
  init(
    id: String,
    type: OperationType,
    payload: Data,
    createdAt: Date,
    retryCount: Int,
    lastAttemptAt: Date?,
    status: OperationStatus,
    lastError: String?
  ) {
    self.id = id
    self.type = type
    self.payload = payload
    self.createdAt = createdAt
    self.retryCount = retryCount
    self.lastAttemptAt = lastAttemptAt
    self.status = status
    self.lastError = lastError
  }
}