import SwiftUI

/// The Back and primary-action bar along the bottom of a multi-step sheet.
struct StepNavigationBar<Primary: View>: View {
    /// Nil hides Back, as on the first step.
    var onBack: (() -> Void)?
    var backIdentifier: String?
    @ViewBuilder let primary: Primary

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// Accessibility text sizes stack the buttons so neither label truncates.
    private var isStacked: Bool {
        dynamicTypeSize.isAccessibilitySize
    }

    var body: some View {
        let layout = isStacked
            ? AnyLayout(VStackLayout(spacing: DesignSystem.Spacing.medium))
            : AnyLayout(HStackLayout(spacing: DesignSystem.Spacing.medium))

        layout {
            if let onBack {
                Button(action: onBack) {
                    HStack(spacing: DesignSystem.Spacing.small) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .accessibilityHidden(true)
                        Text("Back")
                    }
                }
                .buttonStyle(StepBackButtonStyle(fillsWidth: isStacked))
                .accessibilityIdentifier(backIdentifier ?? "")
            }

            primary
        }
        .padding(.horizontal, DesignSystem.Spacing.screenPadding)
        .padding(.vertical, DesignSystem.Spacing.medium)
        .overlay(
            Rectangle()
                .fill(Color.formBorder)
                .frame(height: 0.5),
            alignment: .top
        )
    }
}

/// The tonal secondary action, so Back reads as a peer of the primary button without competing with it.
private struct StepBackButtonStyle: ButtonStyle {
    let fillsWidth: Bool

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)

        configuration.label
            .font(.peatedInteractive)
            .lineLimit(1)
            .foregroundColor(.text)
            .frame(maxWidth: fillsWidth ? .infinity : nil, minHeight: DesignSystem.ControlHeight.large)
            .padding(.horizontal, DesignSystem.Spacing.large)
            .background(configuration.isPressed ? Color.surface : Color.clear, in: shape)
            .overlay(shape.strokeBorder(Color.sectionRule, lineWidth: DesignSystem.Border.thin))
            .contentShape(shape)
    }
}
