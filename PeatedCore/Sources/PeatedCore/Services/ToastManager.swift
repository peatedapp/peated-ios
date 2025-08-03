import Foundation
import SwiftUI

/// Represents a single toast notification
public struct Toast: Identifiable, Equatable {
  public let id = UUID()
  public let message: String
  public let type: ToastType
  public let duration: TimeInterval
  
  public init(message: String, type: ToastType = .info, duration: TimeInterval = 3.0) {
    self.message = message
    self.type = type
    self.duration = duration
  }
  
  public enum ToastType {
    case error
    case success
    case info
    case warning
    
    public var iconName: String {
      switch self {
      case .error: return "xmark.circle.fill"
      case .success: return "checkmark.circle.fill"
      case .info: return "info.circle.fill"
      case .warning: return "exclamationmark.triangle.fill"
      }
    }
    
    public var backgroundColor: Color {
      switch self {
      case .error: return .red
      case .success: return .green
      case .info: return .blue
      case .warning: return .orange
      }
    }
  }
}

/// Manages app-wide toast notifications
@Observable
@MainActor
public class ToastManager {
  /// Singleton instance for global access
  public static let shared = ToastManager()
  
  /// Currently displayed toasts (supports multiple)
  public private(set) var toasts: [Toast] = []
  
  /// Maximum number of toasts to display simultaneously
  private let maxVisibleToasts = 3
  
  /// Queue of pending toasts when max is reached
  private var queuedToasts: [Toast] = []
  
  private init() {}
  
  /// Shows a toast notification
  public func show(_ message: String, type: Toast.ToastType = .info, duration: TimeInterval = 3.0) {
    let toast = Toast(message: message, type: type, duration: duration)
    
    if toasts.count < maxVisibleToasts {
      toasts.append(toast)
      scheduleRemoval(of: toast)
    } else {
      queuedToasts.append(toast)
    }
  }
  
  /// Shows an error toast
  public func showError(_ message: String, duration: TimeInterval = 3.0) {
    show(message, type: .error, duration: duration)
  }
  
  /// Shows a success toast
  public func showSuccess(_ message: String, duration: TimeInterval = 2.5) {
    show(message, type: .success, duration: duration)
  }
  
  /// Shows an info toast
  public func showInfo(_ message: String, duration: TimeInterval = 3.0) {
    show(message, type: .info, duration: duration)
  }
  
  /// Shows a warning toast
  public func showWarning(_ message: String, duration: TimeInterval = 3.5) {
    show(message, type: .warning, duration: duration)
  }
  
  /// Removes a specific toast
  public func remove(_ toast: Toast) {
    withAnimation(.spring(duration: 0.3)) {
      toasts.removeAll { $0.id == toast.id }
    }
    
    // Process queued toasts
    if !queuedToasts.isEmpty {
      let nextToast = queuedToasts.removeFirst()
      toasts.append(nextToast)
      scheduleRemoval(of: nextToast)
    }
  }
  
  /// Removes all toasts immediately
  public func removeAll() {
    withAnimation(.spring(duration: 0.3)) {
      toasts.removeAll()
      queuedToasts.removeAll()
    }
  }
  
  /// Schedules automatic removal of a toast
  private func scheduleRemoval(of toast: Toast) {
    Task {
      try? await Task.sleep(for: .seconds(toast.duration))
      remove(toast)
    }
  }
}

// MARK: - Convenience Extensions

public extension ToastManager {
  /// Shows an API error as a toast
  func showAPIError(_ error: Error) {
    if let apiError = error as? APIError {
      switch apiError {
      case .requestFailed(let message):
        showError(message)
      case .unauthorized:
        showError("Please log in to continue")
      case .networkError:
        showError("Network connection error")
      case .decodingError:
        showError("Unable to process server response")
      default:
        showError("An unexpected error occurred")
      }
    } else {
      showError(error.localizedDescription)
    }
  }
  
  /// Shows a network operation result
  func showResult<T>(_ result: Result<T, Error>, successMessage: String) {
    switch result {
    case .success:
      showSuccess(successMessage)
    case .failure(let error):
      showAPIError(error)
    }
  }
}