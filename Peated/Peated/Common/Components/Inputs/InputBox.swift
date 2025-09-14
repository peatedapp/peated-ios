import SwiftUI

// MARK: - InputBox Modifier
// Centralizes visual styling for inputs (TextField, SecureField, TextEditor).
struct InputBox: ViewModifier {
  enum State {
    case normal
    case focused
    case error
    case disabled
  }

  var state: State = .normal
  var cornerRadius: CGFloat = 10
  var horizontalPadding: CGFloat = 12
  var verticalPadding: CGFloat = 10

  func body(content: Content) -> some View {
    content
      .padding(.horizontal, horizontalPadding)
      .padding(.vertical, verticalPadding)
      .background(Color.surface)
      .overlay(
        RoundedRectangle(cornerRadius: cornerRadius)
          .stroke(borderColor, lineWidth: lineWidth)
      )
      .cornerRadius(cornerRadius)
      .animation(.easeInOut(duration: 0.15), value: stateKey)
  }

  private var borderColor: Color {
    switch state {
    case .disabled:
      return Color.border.opacity(0.35)
    case .error:
      return Color.danger
    case .focused:
      // Use muted tone to avoid bright halos on dark UI
      return Color.textMuted
    case .normal:
      // Match the input background so the outline is effectively hidden by default
      return Color.surface
    }
  }

  private var lineWidth: CGFloat {
    switch state {
    case .focused:
      return 1.5
    case .error:
      return 2
    default:
      return 1
    }
  }

  private var stateKey: Int {
    switch state {
    case .normal: return 0
    case .focused: return 1
    case .error: return 2
    case .disabled: return 3
    }
  }
}

extension View {
  func inputBox(state: InputBox.State = .normal,
                cornerRadius: CGFloat = 10,
                horizontalPadding: CGFloat = 12,
                verticalPadding: CGFloat = 10) -> some View {
    modifier(InputBox(state: state,
                      cornerRadius: cornerRadius,
                      horizontalPadding: horizontalPadding,
                      verticalPadding: verticalPadding))
  }
}
