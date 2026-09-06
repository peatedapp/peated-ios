import SwiftUI

// MARK: - Theme Protocol

protocol AppTheme {
    // Brand
    var brand: Color { get }
    var brandEmphasis: Color { get }
    var onBrand: Color { get }
    // Surfaces
    var background: Color { get }
    var surface: Color { get }
    var surfaceSubtle: Color { get }
    var border: Color { get }
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
    // Status
    var success: Color { get }
    var warning: Color { get }
    var danger: Color { get }
    var info: Color { get }
    var onStatus: Color { get }
    // Domain accents (Flavor categories)
    var flavorSweet: Color { get }
    var flavorFruity: Color { get }
    var flavorSpicy: Color { get }
    var flavorWoody: Color { get }
    var flavorSmoky: Color { get }
    var flavorFloral: Color { get }
    var flavorNutty: Color { get }
    var flavorOther: Color { get }
}

// MARK: - Peated Reference Theme

/// Matches the reference-first ground, ink, and warm-accent system used by peated.com.
struct CreamTheme: AppTheme {
    private enum PaletteLight {
        static let brand = Color(hex: "#9A5B12")
        static let brandEmphasis = Color(hex: "#6E400C")
        static let bg = Color(hex: "#F7F8F5")
        static let surface = Color(hex: "#EBEEE7")
        static let surfaceSubtle = Color(hex: "#DCE0D6")
        static let border = Color(hex: "#161914").opacity(0.11)
        static let formSurface = Color(hex: "#DCE0D6")
        static let formBorder = Color(hex: "#161914").opacity(0.28)
        static let chrome = Color(hex: "#F7F8F5").opacity(0.95)
        static let text = Color(hex: "#161914")
        static let textSecondary = Color(hex: "#4B4E48")
        static let textMuted = Color(hex: "#5B5E58")
        static let onBrand = Color(hex: "#F7F8F5")
        static let onSurface = Color(hex: "#161914")
        static let overlaySoft = Color(hex: "#161914").opacity(0.05)
        static let overlay = Color(hex: "#161914").opacity(0.11)
        static let overlayStrong = Color(hex: "#161914").opacity(0.20)
        static let success = brand
        static let warning = brand
        static let danger = Color(hex: "#A3231A")
        static let info = Color(hex: "#161914").opacity(0.75)
        static let onStatus = Color.white
        static let flavorSweet = brand
        static let flavorFruity = brand.opacity(0.88)
        static let flavorSpicy = brandEmphasis
        static let flavorWoody = brandEmphasis.opacity(0.82)
        static let flavorSmoky = text.opacity(0.46)
        static let flavorFloral = brand.opacity(0.72)
        static let flavorNutty = brandEmphasis.opacity(0.72)
        static let flavorOther = text.opacity(0.62)
    }

    private enum PaletteDark {
        static let brand = Color(hex: "#D9922F")
        static let brandEmphasis = Color(hex: "#E8A752")
        static let bg = Color(hex: "#101210")
        static let surface = Color(hex: "#1B1E1A")
        static let surfaceSubtle = Color(hex: "#2B2F29")
        static let border = Color(hex: "#E8EAE3").opacity(0.11)
        static let formSurface = Color(hex: "#2B2F29")
        static let formBorder = Color(hex: "#E8EAE3").opacity(0.32)
        static let chrome = Color(hex: "#101210").opacity(0.95)
        static let text = Color(hex: "#E8EAE3")
        static let textSecondary = Color(hex: "#B2B4AE")
        static let textMuted = Color(hex: "#A0A29D")
        static let onBrand = Color(hex: "#101210")
        static let onSurface = Color(hex: "#E8EAE3")
        static let overlaySoft = Color(hex: "#E8EAE3").opacity(0.05)
        static let overlay = Color(hex: "#E8EAE3").opacity(0.11)
        static let overlayStrong = Color(hex: "#E8EAE3").opacity(0.20)
        static let success = brand
        static let warning = brand
        static let danger = Color(hex: "#F0776B")
        static let info = Color(hex: "#E8EAE3").opacity(0.75)
        static let onStatus = Color(hex: "#101210")
        static let flavorSweet = brand
        static let flavorFruity = brand.opacity(0.88)
        static let flavorSpicy = brandEmphasis
        static let flavorWoody = brandEmphasis.opacity(0.82)
        static let flavorSmoky = text.opacity(0.46)
        static let flavorFloral = brand.opacity(0.72)
        static let flavorNutty = brandEmphasis.opacity(0.72)
        static let flavorOther = text.opacity(0.62)
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

    var border: Color {
        dynamic(PaletteLight.border, PaletteDark.border)
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

    var info: Color {
        dynamic(PaletteLight.info, PaletteDark.info)
    }

    var onStatus: Color {
        dynamic(PaletteLight.onStatus, PaletteDark.onStatus)
    }

    /// Domain accents
    var flavorSweet: Color {
        dynamic(PaletteLight.flavorSweet, PaletteDark.flavorSweet)
    }

    var flavorFruity: Color {
        dynamic(PaletteLight.flavorFruity, PaletteDark.flavorFruity)
    }

    var flavorSpicy: Color {
        dynamic(PaletteLight.flavorSpicy, PaletteDark.flavorSpicy)
    }

    var flavorWoody: Color {
        dynamic(PaletteLight.flavorWoody, PaletteDark.flavorWoody)
    }

    var flavorSmoky: Color {
        dynamic(PaletteLight.flavorSmoky, PaletteDark.flavorSmoky)
    }

    var flavorFloral: Color {
        dynamic(PaletteLight.flavorFloral, PaletteDark.flavorFloral)
    }

    var flavorNutty: Color {
        dynamic(PaletteLight.flavorNutty, PaletteDark.flavorNutty)
    }

    var flavorOther: Color {
        dynamic(PaletteLight.flavorOther, PaletteDark.flavorOther)
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
