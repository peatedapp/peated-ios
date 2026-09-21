import SwiftUI

enum DesignSystem {
    /// Glyph and figure sizes for rating components that size text to their geometry.
    /// Interface text uses the `Font.peated*` roles instead.
    enum FontSize {
        static let tiny: CGFloat = 10
        static let caption: CGFloat = 11
        static let small: CGFloat = 13
        static let large: CGFloat = 16
    }

    /// Letter spacing for the display roles, in points at the role's base size.
    enum Tracking {
        static let pageTitle: CGFloat = -1.8 // -0.045em at 40
        static let pageTitleCompact: CGFloat = -1.28 // -0.04em at 32
        static let sectionHeading: CGFloat = -0.5 // -0.025em at 20
        static let rowTitle: CGFloat = -0.45 // -0.025em at 18
        static let rowTitleCompact: CGFloat = -0.375 // -0.025em at 15
    }

    /// The 4-point scale shared with the web: 4, 8, 12, 16, 24, 32, and 48.
    enum Spacing {
        static let xSmall: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xLarge: CGFloat = 24
        static let xxLarge: CGFloat = 32
        static let xxxLarge: CGFloat = 48
        static let cardPadding: CGFloat = 16
        static let screenPadding: CGFloat = 16
    }

    /// Controls and framed regions use 3. Chips, tags, image slots, and bar segments use 2. No pills.
    enum CornerRadius {
        static let small: CGFloat = 2
        static let medium: CGFloat = 3
        static let large: CGFloat = 3
    }

    /// Use 40 by default and 44 on touch screens. Controls in one action row share a height.
    enum ControlHeight {
        static let small: CGFloat = 34
        static let standard: CGFloat = 44
        static let large: CGFloat = 44
    }

    enum ImageSize {
        static let bottleThumb = CGSize(width: 42, height: 58)
        static let bottleLarge = CGSize(width: 50, height: 70)
        static let avatar = CGSize(width: 32, height: 32)
        static let avatarLarge = CGSize(width: 48, height: 48)
        static let photoThumb = CGSize(width: 80, height: 80)
        static let photoMax: CGFloat = 200
    }

    enum Opacity {
        static let subtle: Double = 0.1
        static let light: Double = 0.3
        static let medium: Double = 0.5
        static let semiOpaque: Double = 0.6
        static let dimmed: Double = 0.7
        static let strong: Double = 0.8
        static let almostFull: Double = 0.9
    }

    enum Animation {
        static let defaultDuration: Double = 0.3
        static let quickDuration: Double = 0.2
        static let slowDuration: Double = 0.5
    }

    enum Border {
        static let thin: CGFloat = 1
        static let medium: CGFloat = 1.5
        static let thick: CGFloat = 2
    }

    /// Floating overlays are the only elements that cast a shadow.
    enum OverlayShadow {
        static let radius: CGFloat = 20
        static let y: CGFloat = 18
    }
}

// MARK: - View Extensions for Easy Access

extension View {
    func cardStyle() -> some View {
        padding(DesignSystem.Spacing.cardPadding)
            .background(Color.surface)
            .cornerRadius(DesignSystem.CornerRadius.large)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                    .stroke(Color.border.opacity(DesignSystem.Opacity.light), lineWidth: DesignSystem.Border.thin)
            )
    }

    func bottleCardStyle(isSelected: Bool = false) -> some View {
        padding(DesignSystem.Spacing.medium)
            .background(Color.surface.opacity(DesignSystem.Opacity.semiOpaque))
            .cornerRadius(DesignSystem.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .stroke(
                        isSelected ? Color.brand : Color.border.opacity(DesignSystem.Opacity.light),
                        lineWidth: isSelected ? DesignSystem.Border.thick : DesignSystem.Border.thin
                    )
            )
    }

    /// Shadow for menus, typeahead results, and dialogs. Web: `0 18px 40px`, 16% ink or 55% black.
    func overlayShadow() -> some View {
        shadow(
            color: Color.overlayShadow,
            radius: DesignSystem.OverlayShadow.radius,
            x: 0,
            y: DesignSystem.OverlayShadow.y
        )
    }
}
