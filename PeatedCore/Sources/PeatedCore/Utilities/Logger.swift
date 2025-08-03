import Foundation
import os.log

/// Centralized logging utility using Apple's unified logging system
public struct Logger {
  
  // MARK: - Categories
  
  /// API-related logging (requests, responses, errors)
  public static let api = os.Logger(subsystem: "com.peated.PeatedCore", category: "API")
  
  /// Model state changes and business logic
  public static let model = os.Logger(subsystem: "com.peated.PeatedCore", category: "Model")
  
  /// Authentication and user session management
  public static let auth = os.Logger(subsystem: "com.peated.PeatedCore", category: "Auth")
  
  /// Network connectivity and offline operations
  public static let network = os.Logger(subsystem: "com.peated.PeatedCore", category: "Network")
  
  /// Database operations and caching
  public static let database = os.Logger(subsystem: "com.peated.PeatedCore", category: "Database")
  
  /// Sync operations and background tasks
  public static let sync = os.Logger(subsystem: "com.peated.PeatedCore", category: "Sync")
  
  // MARK: - Convenience Methods
  
  /// Log API request with standardized format
  public static func logAPIRequest(
    endpoint: String,
    method: String = "GET",
    parameters: [String: Any]? = nil
  ) {
    var message = "API \(method) \(endpoint)"
    if let params = parameters, !params.isEmpty {
      message += " with params: \(params)"
    }
    api.info("\(message, privacy: .public)")
  }
  
  /// Log API response with standardized format
  public static func logAPIResponse(
    endpoint: String,
    statusCode: Int? = nil,
    resultCount: Int? = nil,
    duration: TimeInterval? = nil
  ) {
    var message = "API response \(endpoint)"
    if let status = statusCode {
      message += " (\(status))"
    }
    if let count = resultCount {
      message += " - \(count) items"
    }
    if let time = duration {
      message += " in \(String(format: "%.3f", time))s"
    }
    api.info("\(message, privacy: .public)")
  }
  
  /// Log API error with context
  public static func logAPIError(
    endpoint: String,
    error: Error,
    context: [String: Any]? = nil
  ) {
    var message = "API error \(endpoint): \(error.localizedDescription)"
    if let ctx = context {
      message += " context: \(ctx)"
    }
    api.error("\(message, privacy: .public)")
  }
  
  /// Log model state change
  public static func logModelUpdate(
    modelName: String,
    action: String,
    details: String? = nil
  ) {
    var message = "\(modelName): \(action)"
    if let details = details {
      message += " - \(details)"
    }
    model.info("\(message, privacy: .public)")
  }
  
  /// Log authentication events
  public static func logAuthEvent(
    event: String,
    userId: String? = nil,
    success: Bool = true
  ) {
    let status = success ? "success" : "failure"
    var message = "Auth \(event) - \(status)"
    if let id = userId {
      message += " (user: \(id))"
    }
    auth.info("\(message, privacy: .public)")
  }
  
  /// Log network connectivity changes
  public static func logNetworkChange(
    connected: Bool,
    connectionType: String? = nil
  ) {
    let status = connected ? "connected" : "disconnected"
    var message = "Network \(status)"
    if let type = connectionType {
      message += " (\(type))"
    }
    network.info("\(message, privacy: .public)")
  }
  
  /// Log database operations
  public static func logDatabaseOperation(
    operation: String,
    table: String? = nil,
    recordCount: Int? = nil,
    duration: TimeInterval? = nil
  ) {
    var message = "DB \(operation)"
    if let table = table {
      message += " \(table)"
    }
    if let count = recordCount {
      message += " (\(count) records)"
    }
    if let time = duration {
      message += " in \(String(format: "%.3f", time))s"
    }
    database.info("\(message, privacy: .public)")
  }
  
  /// Log sync operations
  public static func logSyncOperation(
    operation: String,
    entityType: String? = nil,
    count: Int? = nil,
    success: Bool = true
  ) {
    let status = success ? "completed" : "failed"
    var message = "Sync \(operation) \(status)"
    if let type = entityType {
      message += " \(type)"
    }
    if let count = count {
      message += " (\(count) items)"
    }
    
    if success {
      sync.info("\(message, privacy: .public)")
    } else {
      sync.error("\(message, privacy: .public)")
    }
  }
}

// MARK: - Privacy Helpers

extension Logger {
  /// Helper to format user-sensitive data with appropriate privacy levels
  public static func formatUserData(_ data: String) -> String {
    // In production, this could hash or truncate sensitive data
    return data
  }
  
  /// Helper to format system data (safe to log)
  public static func formatSystemData(_ data: Any) -> String {
    return String(describing: data)
  }
}