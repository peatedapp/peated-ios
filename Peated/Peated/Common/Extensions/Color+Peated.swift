import SwiftUI

/// Semantic tokens resolve through the current AppTheme.
extension Color {
    /// Brand
    static var brand: Color {
        ThemeProvider.current.brand
    }

    static var brandEmphasis: Color {
        ThemeProvider.current.brandEmphasis
    }

    /// 15% brand for selected and related data.
    static var brandTint: Color {
        ThemeProvider.current.brandTint
    }

    static var onBrand: Color {
        ThemeProvider.current.onBrand
    }

    /// Surfaces
    static var background: Color {
        ThemeProvider.current.background
    }

    static var surface: Color {
        ThemeProvider.current.surface
    }

    /// Fields and neutral tracks.
    static var surfaceSubtle: Color {
        ThemeProvider.current.surfaceSubtle
    }

    /// Deepest neutral surface, used for rating tracks on tonal surfaces.
    static var surfaceSunken: Color {
        ThemeProvider.current.surfaceSunken
    }

    /// Catalog image canvas. Always white in both appearances.
    static var imageBackground: Color {
        ThemeProvider.current.imageBackground
    }

    static var border: Color {
        ThemeProvider.current.border
    }

    /// Stronger hairline for chip and section outlines.
    static var sectionRule: Color {
        ThemeProvider.current.sectionRule
    }

    static var formSurface: Color {
        ThemeProvider.current.formSurface
    }

    static var formBorder: Color {
        ThemeProvider.current.formBorder
    }

    static var chrome: Color {
        ThemeProvider.current.chrome
    }

    /// Text
    static var text: Color {
        ThemeProvider.current.text
    }

    static var textSecondary: Color {
        ThemeProvider.current.textSecondary
    }

    static var textMuted: Color {
        ThemeProvider.current.textMuted
    }

    static var onSurface: Color {
        ThemeProvider.current.onSurface
    }

    /// Overlays
    static var overlaySoft: Color {
        ThemeProvider.current.overlaySoft
    }

    static var overlay: Color {
        ThemeProvider.current.overlay
    }

    static var overlayStrong: Color {
        ThemeProvider.current.overlayStrong
    }

    /// Shadow color for floating overlays. See `View.overlayShadow()`.
    static var overlayShadow: Color {
        ThemeProvider.current.overlayShadow
    }

    /// Data
    static var dataAccent: Color {
        ThemeProvider.current.dataAccent
    }

    static var dataRange: Color {
        ThemeProvider.current.dataRange
    }

    static var ratingFill: Color {
        ThemeProvider.current.ratingFill
    }

    static var ratingTrack: Color {
        ThemeProvider.current.ratingTrack
    }

    static var passportEmpty: Color {
        ThemeProvider.current.passportEmpty
    }

    /// Status
    static var success: Color {
        ThemeProvider.current.success
    }

    static var warning: Color {
        ThemeProvider.current.warning
    }

    static var danger: Color {
        ThemeProvider.current.danger
    }

    static var dangerQuiet: Color {
        ThemeProvider.current.dangerQuiet
    }

    static var info: Color {
        ThemeProvider.current.info
    }

    static var onStatus: Color {
        ThemeProvider.current.onStatus
    }

    /// Tasting-note categories. Use them only to connect one category across the tasting
    /// wheel, note vocabulary, saved tags, and flavor charts, never for text or actions.
    static var categoryCereal: Color {
        ThemeProvider.current.categoryCereal
    }

    static var categoryFruit: Color {
        ThemeProvider.current.categoryFruit
    }

    static var categoryFloral: Color {
        ThemeProvider.current.categoryFloral
    }

    static var categorySmoke: Color {
        ThemeProvider.current.categorySmoke
    }

    static var categoryEarthy: Color {
        ThemeProvider.current.categoryEarthy
    }

    static var categorySulfur: Color {
        ThemeProvider.current.categorySulfur
    }

    static var categorySweet: Color {
        ThemeProvider.current.categorySweet
    }

    static var categorySpice: Color {
        ThemeProvider.current.categorySpice
    }

    static var categoryWood: Color {
        ThemeProvider.current.categoryWood
    }

    /// Color for an API tag category raw value. Unknown categories return nil so callers fall
    /// back to the neutral tag border.
    static func tastingCategory(named name: String) -> Color? {
        switch name {
        case "cereal": categoryCereal
        case "fruit": categoryFruit
        case "floral": categoryFloral
        case "smoke": categorySmoke
        case "earthy": categoryEarthy
        case "sulfur": categorySulfur
        case "sweet": categorySweet
        case "spice": categorySpice
        case "wood": categoryWood
        default: nil
        }
    }

    // No legacy aliases are kept; use semantic tokens above.
}

/// Helper extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
