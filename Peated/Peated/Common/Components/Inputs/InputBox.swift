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
    var cornerRadius: CGFloat = DesignSystem.CornerRadius.medium
    var horizontalPadding: CGFloat = 13
    var verticalPadding: CGFloat = 10

    /// Matches the web field: an inset fill with no outline at rest, a 2pt ring
    /// drawn inside the box for focus and errors, and a faded disabled state.
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius)

        content
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(minHeight: DesignSystem.ControlHeight.large)
            .background(Color.formSurface, in: shape)
            .overlay {
                if let ringColor {
                    shape.strokeBorder(ringColor, lineWidth: DesignSystem.Border.thick)
                }
            }
            .opacity(state == .disabled ? 0.45 : 1)
            .animation(.easeInOut(duration: 0.15), value: state)
    }

    private var ringColor: Color? {
        switch state {
        case .focused: .brand
        case .error: .danger
        case .normal, .disabled: nil
        }
    }
}

extension View {
    func inputBox(state: InputBox.State = .normal,
                  cornerRadius: CGFloat = DesignSystem.CornerRadius.medium,
                  horizontalPadding: CGFloat = 13,
                  verticalPadding: CGFloat = 10) -> some View {
        modifier(InputBox(state: state,
                          cornerRadius: cornerRadius,
                          horizontalPadding: horizontalPadding,
                          verticalPadding: verticalPadding))
    }
}
