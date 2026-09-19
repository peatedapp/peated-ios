import SwiftUI

// MARK: - Theme Protocol

/// Semantic color tokens. Names map to `../peated/DESIGN.md` as follows:
/// brand = accent, brandEmphasis = accentDeep, background = ground, surfaceSubtle = inset,
/// border = hairline, text = ink, textSecondary = inkMuted, danger = critical.
protocol AppTheme {
    // Brand
    var brand: Color { get }
    var brandEmphasis: Color { get }
    var brandTint: Color { get }
    var onBrand: Color { get }
    // Surfaces
    var background: Color { get }
    var surface: Color { get }
    var surfaceSubtle: Color { get }
    var surfaceSunken: Color { get }
    var imageBackground: Color { get }
    var border: Color { get }
    var sectionRule: Color { get }
    var formSurface: Color { get }
    var formBorder: Color { get }
    // App chrome (nav/tab bars)
    var chrome: Color { get }
    // Text
    var text: Color { get }
    var textSecondary: Color { get }
    var textMuted: Color { get }
    var onSurface: Color { get }
    // Overlays
    var overlaySoft: Color { get }
    var overlay: Color { get }
    var overlayStrong: Color { get }
    var overlayShadow: Color { get }
    // Data
    var dataAccent: Color { get }
    var dataRange: Color { get }
    var ratingFill: Color { get }
    var ratingTrack: Color { get }
    var passportEmpty: Color { get }
    // Status
    var success: Color { get }
    var warning: Color { get }
    var danger: Color { get }
    var dangerQuiet: Color { get }
    var info: Color { get }
    var onStatus: Color { get }
    // Tasting-note categories
    var categoryCereal: Color { get }
    var categoryFruit: Color { get }
    var categoryFloral: Color { get }
    var categorySmoke: Color { get }
    var categoryEarthy: Color { get }
    var categorySulfur: Color { get }
    var categorySweet: Color { get }
    var categorySpice: Color { get }
    var categoryWood: Color { get }
}

// MARK: - Peated Reference Theme

/// Matches the reference-first ground, ink, and warm-accent system used by peated.com.
/// Values come from `../peated/apps/web/src/styles/tokens.stylex.ts`.
struct CreamTheme: AppTheme {
    private enum PaletteLight {
        static let ink = Color(hex: "#161914")
        static let ground = Color(hex: "#F7F8F5")
        static let brand = Color(hex: "#9A5B12")
        static let brandEmphasis = Color(hex: "#6E400C")
        static let brandTint = brand.opacity(0.15)
        static let bg = ground
        static let surface = Color(hex: "#EBEEE7")
        static let surfaceSubtle = Color(hex: "#DCE0D6")
        static let surfaceSunken = Color(hex: "#CBD0C2")
        static let imageBackground = Color.white
        static let border = ink.opacity(0.11)
        static let sectionRule = ink.opacity(0.16)
        static let formSurface = surfaceSubtle
        static let formBorder = ink.opacity(0.28)
        static let chrome = ground.opacity(0.95)
        static let text = ink
        static let textSecondary = Color(hex: "#4B4E48")
        static let textMuted = Color(hex: "#5B5E58")
        static let onBrand = ground
        static let onSurface = ink
        static let overlaySoft = ink.opacity(0.05)
        static let overlay = ink.opacity(0.11)
        static let overlayStrong = ink.opacity(0.20)
        static let overlayShadow = ink.opacity(0.16)
        static let dataAccent = brand.opacity(0.42)
        static let dataRange = ink.opacity(0.45)
        static let ratingFill = brand.opacity(0.75)
        static let ratingTrack = surfaceSunken
        static let passportEmpty = ink.opacity(0.16)
        static let success = brand
        static let warning = brand
        static let danger = Color(hex: "#A3231A")
        static let dangerQuiet = danger.opacity(0.42)
        static let info = ink.opacity(0.75)
        static let onStatus = Color.white
        static let categoryCereal = Color(hex: "#AD6F0B")
        static let categoryFruit = Color(hex: "#9F2F50")
        static let categoryFloral = Color(hex: "#6F4A9B")
        static let categorySmoke = Color(hex: "#2C7089")
        static let categoryEarthy = Color(hex: "#356B48")
        static let categorySulfur = Color(hex: "#707A16")
        static let categorySweet = Color(hex: "#C06092")
        static let categorySpice = Color(hex: "#BD4822")
        static let categoryWood = Color(hex: "#5C4437")
    }

    private enum PaletteDark {
        static let ink = Color(hex: "#E8EAE3")
        static let ground = Color(hex: "#101210")
        static let brand = Color(hex: "#D9922F")
        static let brandEmphasis = Color(hex: "#E8A752")
        static let brandTint = brand.opacity(0.15)
        static let bg = ground
        static let surface = Color(hex: "#1B1E1A")
        static let surfaceSubtle = Color(hex: "#2B2F29")
        static let surfaceSunken = Color(hex: "#3A3F37")
        static let imageBackground = Color.white
        static let border = ink.opacity(0.11)
        static let sectionRule = ink.opacity(0.16)
        static let formSurface = surfaceSubtle
        static let formBorder = ink.opacity(0.32)
        static let chrome = ground.opacity(0.95)
        static let text = ink
        static let textSecondary = Color(hex: "#B2B4AE")
        static let textMuted = Color(hex: "#A0A29D")
        static let onBrand = ground
        static let onSurface = ink
        static let overlaySoft = ink.opacity(0.05)
        static let overlay = ink.opacity(0.11)
        static let overlayStrong = ink.opacity(0.20)
        static let overlayShadow = Color.black.opacity(0.55)
        static let dataAccent = brand.opacity(0.42)
        static let dataRange = ink.opacity(0.45)
        static let ratingFill = brand.opacity(0.75)
        static let ratingTrack = surfaceSunken
        static let passportEmpty = ink.opacity(0.16)
        static let success = brand
        static let warning = brand
        static let danger = Color(hex: "#F0776B")
        static let dangerQuiet = danger.opacity(0.42)
        static let info = ink.opacity(0.75)
        static let onStatus = ground
        static let categoryCereal = Color(hex: "#E2A744")
        static let categoryFruit = Color(hex: "#D86485")
        static let categoryFloral = Color(hex: "#AA8CD0")
        static let categorySmoke = Color(hex: "#76A5B5")
        static let categoryEarthy = Color(hex: "#75A181")
        static let categorySulfur = Color(hex: "#B3B65F")
        static let categorySweet = Color(hex: "#E6A0C0")
        static let categorySpice = Color(hex: "#DF7B58")
        static let categoryWood = Color(hex: "#9A7660")
    }

    private func dynamic(_ light: Color, _ dark: Color) -> Color {
        #if os(iOS)
            return Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light) })
        #else
            return light
        #endif
    }

    /// Brand
    var brand: Color {
        dynamic(PaletteLight.brand, PaletteDark.brand)
    }

    var brandEmphasis: Color {
        dynamic(PaletteLight.brandEmphasis, PaletteDark.brandEmphasis)
    }

    var brandTint: Color {
        dynamic(PaletteLight.brandTint, PaletteDark.brandTint)
    }

    var onBrand: Color {
        dynamic(PaletteLight.onBrand, PaletteDark.onBrand)
    }

    /// Surfaces
    var background: Color {
        dynamic(PaletteLight.bg, PaletteDark.bg)
    }

    var surface: Color {
        dynamic(PaletteLight.surface, PaletteDark.surface)
    }

    var surfaceSubtle: Color {
        dynamic(PaletteLight.surfaceSubtle, PaletteDark.surfaceSubtle)
    }

    var surfaceSunken: Color {
        dynamic(PaletteLight.surfaceSunken, PaletteDark.surfaceSunken)
    }

    var imageBackground: Color {
        dynamic(PaletteLight.imageBackground, PaletteDark.imageBackground)
    }

    var border: Color {
        dynamic(PaletteLight.border, PaletteDark.border)
    }

    var sectionRule: Color {
        dynamic(PaletteLight.sectionRule, PaletteDark.sectionRule)
    }

    var formSurface: Color {
        dynamic(PaletteLight.formSurface, PaletteDark.formSurface)
    }

    var formBorder: Color {
        dynamic(PaletteLight.formBorder, PaletteDark.formBorder)
    }

    var chrome: Color {
        dynamic(PaletteLight.chrome, PaletteDark.chrome)
    }

    /// Text
    var text: Color {
        dynamic(PaletteLight.text, PaletteDark.text)
    }

    var textSecondary: Color {
        dynamic(PaletteLight.textSecondary, PaletteDark.textSecondary)
    }

    var textMuted: Color {
        dynamic(PaletteLight.textMuted, PaletteDark.textMuted)
    }

    var onSurface: Color {
        dynamic(PaletteLight.onSurface, PaletteDark.onSurface)
    }

    /// Overlays
    var overlaySoft: Color {
        dynamic(PaletteLight.overlaySoft, PaletteDark.overlaySoft)
    }

    var overlay: Color {
        dynamic(PaletteLight.overlay, PaletteDark.overlay)
    }

    var overlayStrong: Color {
        dynamic(PaletteLight.overlayStrong, PaletteDark.overlayStrong)
    }

    var overlayShadow: Color {
        dynamic(PaletteLight.overlayShadow, PaletteDark.overlayShadow)
    }

    /// Data
    var dataAccent: Color {
        dynamic(PaletteLight.dataAccent, PaletteDark.dataAccent)
    }

    var dataRange: Color {
        dynamic(PaletteLight.dataRange, PaletteDark.dataRange)
    }

    var ratingFill: Color {
        dynamic(PaletteLight.ratingFill, PaletteDark.ratingFill)
    }

    var ratingTrack: Color {
        dynamic(PaletteLight.ratingTrack, PaletteDark.ratingTrack)
    }

    var passportEmpty: Color {
        dynamic(PaletteLight.passportEmpty, PaletteDark.passportEmpty)
    }

    /// Status
    var success: Color {
        dynamic(PaletteLight.success, PaletteDark.success)
    }

    var warning: Color {
        dynamic(PaletteLight.warning, PaletteDark.warning)
    }

    var danger: Color {
        dynamic(PaletteLight.danger, PaletteDark.danger)
    }

    var dangerQuiet: Color {
        dynamic(PaletteLight.dangerQuiet, PaletteDark.dangerQuiet)
    }

    var info: Color {
        dynamic(PaletteLight.info, PaletteDark.info)
    }

    var onStatus: Color {
        dynamic(PaletteLight.onStatus, PaletteDark.onStatus)
    }

    /// Tasting-note categories
    var categoryCereal: Color {
        dynamic(PaletteLight.categoryCereal, PaletteDark.categoryCereal)
    }

    var categoryFruit: Color {
        dynamic(PaletteLight.categoryFruit, PaletteDark.categoryFruit)
    }

    var categoryFloral: Color {
        dynamic(PaletteLight.categoryFloral, PaletteDark.categoryFloral)
    }

    var categorySmoke: Color {
        dynamic(PaletteLight.categorySmoke, PaletteDark.categorySmoke)
    }

    var categoryEarthy: Color {
        dynamic(PaletteLight.categoryEarthy, PaletteDark.categoryEarthy)
    }

    var categorySulfur: Color {
        dynamic(PaletteLight.categorySulfur, PaletteDark.categorySulfur)
    }

    var categorySweet: Color {
        dynamic(PaletteLight.categorySweet, PaletteDark.categorySweet)
    }

    var categorySpice: Color {
        dynamic(PaletteLight.categorySpice, PaletteDark.categorySpice)
    }

    var categoryWood: Color {
        dynamic(PaletteLight.categoryWood, PaletteDark.categoryWood)
    }
}

// MARK: - Theme Manager

final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    @Published var theme: AppTheme = CreamTheme()
}

extension EnvironmentValues {
    @Entry var appTheme: AppTheme = ThemeManager.shared.theme
}

extension View {
    func appTheme(_ theme: AppTheme) -> some View {
        environment(\.appTheme, theme)
    }
}

/// Internal provider used by Color tokens to resolve current theme.
enum ThemeProvider {
    static var current: AppTheme {
        ThemeManager.shared.theme
    }
}
