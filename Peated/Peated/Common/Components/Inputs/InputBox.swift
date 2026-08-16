import SwiftUI

// MARK: - InputBox Modifier

/// Centralizes visual styling for inputs (TextField, SecureField, TextEditor).
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
            .background(Color.formSurface)
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
            Color.formBorder.opacity(0.35)
        case .error:
            Color.danger
        case .focused:
            Color.brand
        case .normal:
            // Match the input background so the outline is effectively hidden by default
            Color.formSurface
        }
    }

    private var lineWidth: CGFloat {
        switch state {
        case .focused:
            1.5
        case .error:
            2
        default:
            1
        }
    }

    private var stateKey: Int {
        switch state {
        case .normal: 0
        case .focused: 1
        case .error: 2
        case .disabled: 3
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
