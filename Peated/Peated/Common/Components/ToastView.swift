import SwiftUI

struct ToastView: View {
  let message: String
  let type: ToastType
  
  enum ToastType {
    case error
    case success
    case info
    case warning
    
    var backgroundColor: Color {
      switch self {
      case .error: return Color.red
      case .success: return Color.green
      case .info: return Color.blue
      case .warning: return Color.orange
      }
    }
    
    var iconName: String {
      switch self {
      case .error: return "xmark.circle.fill"
      case .success: return "checkmark.circle.fill"
      case .info: return "info.circle.fill"
      case .warning: return "exclamationmark.triangle.fill"
      }
    }
  }
  
  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: type.iconName)
        .font(.system(size: 20))
        .foregroundColor(.white)
      
      Text(message)
        .font(.system(size: 14, weight: .medium))
        .foregroundColor(.white)
        .multilineTextAlignment(.leading)
      
      Spacer(minLength: 0)
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(type.backgroundColor)
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
  }
}


// Toast modifier for easy usage
struct ToastModifier: ViewModifier {
  @Binding var isShowing: Bool
  let message: String
  let type: ToastView.ToastType
  let duration: TimeInterval
  
  func body(content: Content) -> some View {
    ZStack {
      content
      
      if isShowing {
        VStack {
          ToastView(message: message, type: type)
            .padding(.horizontal)
            .transition(.asymmetric(
              insertion: .move(edge: .top).combined(with: .opacity),
              removal: .move(edge: .top).combined(with: .opacity)
            ))
            .onAppear {
              DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                withAnimation(.easeInOut(duration: 0.3)) {
                  isShowing = false
                }
              }
            }
          
          Spacer()
        }
        .padding(.top, 50) // Account for status bar
      }
    }
  }
}

extension View {
  func toast(
    isShowing: Binding<Bool>,
    message: String,
    type: ToastView.ToastType = .info,
    duration: TimeInterval = 3.0
  ) -> some View {
    modifier(ToastModifier(
      isShowing: isShowing,
      message: message,
      type: type,
      duration: duration
    ))
  }
}

#Preview {
  VStack(spacing: 20) {
    ToastView(message: "You can't toast your own tastings", type: .error)
    ToastView(message: "Tasting toasted!", type: .success)
    ToastView(message: "Loading more tastings...", type: .info)
  }
  .padding()
}