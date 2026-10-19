import SwiftUI

/// Full-width, leading-aligned buttons for the sign-in and sign-up screens.
/// Matches the large `tonal` and `accent` button variants on peated.com.
struct AuthButtonStyle: ButtonStyle {
    enum Variant {
        /// Transparent with a hairline outline. Used for each sign-in method.
        case tonal
        /// Filled brand color. Used for the single submit action.
        case accent
    }

    var variant: Variant = .tonal

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)

        configuration.label
            .labelStyle(IconSlotLabelStyle())
            .font(.peatedInteractive)
            .foregroundColor(foreground)
            .frame(maxWidth: .infinity, minHeight: DesignSystem.ControlHeight.large, alignment: .leading)
            .padding(.horizontal, 20)
            .background(background(isPressed: configuration.isPressed), in: shape)
            .overlay {
                if variant == .tonal {
                    shape.strokeBorder(Color.sectionRule, lineWidth: DesignSystem.Border.thin)
                }
            }
            .contentShape(shape)
    }

    /// Disabled buttons use muted colors instead of fading, so their text keeps readable contrast.
    private var foreground: Color {
        guard isEnabled else { return .textMuted }
        return variant == .accent ? .onBrand : .text
    }

    private func background(isPressed: Bool) -> Color {
        switch variant {
        case .tonal:
            isPressed ? .surface : .clear
        case .accent where !isEnabled:
            .surfaceSubtle
        case .accent:
            isPressed ? .brandEmphasis : .brand
        }
    }
}

/// Puts every icon in the same slot so the titles of stacked buttons line up.
private struct IconSlotLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 10) {
            configuration.icon
                .font(.system(size: 17, weight: .medium))
                .frame(width: 20)
            configuration.title
        }
    }
}

extension ButtonStyle where Self == AuthButtonStyle {
    static var authTonal: AuthButtonStyle {
        AuthButtonStyle(variant: .tonal)
    }

    static var authAccent: AuthButtonStyle {
        AuthButtonStyle(variant: .accent)
    }
}
