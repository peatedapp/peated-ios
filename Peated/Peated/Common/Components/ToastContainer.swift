import SwiftUI
import PeatedCore

/// Container view that displays toast notifications
struct ToastContainer: View {
  @State private var toastManager = ToastManager.shared
  
  var body: some View {
    VStack(spacing: 8) {
      ForEach(toastManager.toasts) { toast in
        ToastView(
          message: toast.message,
          type: ToastView.ToastType(from: toast.type)
        )
        .transition(
          .asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
          )
        )
        .id(toast.id)
        .onTapGesture {
          toastManager.remove(toast)
        }
      }
    }
    .padding(.horizontal, 16)
    .padding(.top, 8)
    .animation(.spring(duration: 0.3), value: toastManager.toasts)
  }
}

// MARK: - View Modifier

struct ToastContainerModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .overlay(alignment: .top) {
        ToastContainer()
          .allowsHitTesting(true) // Allow tap to dismiss
      }
  }
}

extension View {
  /// Adds toast container to the view hierarchy
  func withToastContainer() -> some View {
    modifier(ToastContainerModifier())
  }
}

// MARK: - Type Conversion

extension ToastView.ToastType {
  init(from coreType: Toast.ToastType) {
    switch coreType {
    case .error: self = .error
    case .success: self = .success
    case .info: self = .info
    case .warning: self = .warning
    }
  }
}