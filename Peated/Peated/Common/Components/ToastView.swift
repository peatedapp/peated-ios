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


#Preview {
  VStack(spacing: 20) {
    ToastView(message: "You can't toast your own tastings", type: .error)
    ToastView(message: "Tasting toasted!", type: .success)
    ToastView(message: "Loading more tastings...", type: .info)
  }
  .padding()
}