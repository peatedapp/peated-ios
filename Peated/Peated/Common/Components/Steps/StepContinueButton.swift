import SwiftUI

/// The filled primary action in a `StepNavigationBar`. It fills the space Back leaves.
struct StepContinueButton: View {
    let title: String
    var showsChevron = true
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.small) {
                Text(title)
                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .accessibilityHidden(true)
                }
            }
        }
        .buttonStyle(.stepPrimary)
        .disabled(!isEnabled)
    }
}

/// The filled, full-width look shared by every primary action in a step bar.
struct StepPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)

        configuration.label
            .font(.peatedInteractive)
            .lineLimit(1)
            // A solid muted surface keeps the disabled label readable; a
            // translucent brand fill does not meet the contrast minimum.
            .foregroundColor(isEnabled ? .onBrand : .textSecondary)
            .frame(maxWidth: .infinity, minHeight: DesignSystem.ControlHeight.large)
            .padding(.horizontal, DesignSystem.Spacing.large)
            .background(background(isPressed: configuration.isPressed), in: shape)
            .overlay {
                if !isEnabled {
                    shape.strokeBorder(Color.formBorder, lineWidth: DesignSystem.Border.thin)
                }
            }
            .contentShape(shape)
    }

    private func background(isPressed: Bool) -> Color {
        guard isEnabled else { return .formSurface }
        return isPressed ? .brandEmphasis : .brand
    }
}

extension ButtonStyle where Self == StepPrimaryButtonStyle {
    static var stepPrimary: StepPrimaryButtonStyle {
        StepPrimaryButtonStyle()
    }
}
