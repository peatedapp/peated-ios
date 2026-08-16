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

// MARK: - Classic Peated Theme (Slate + Amber)

/// Uses slate backgrounds with white text and amber highlights, matching peated.com.
struct CreamTheme: AppTheme {
    /// We intentionally keep both palettes aligned so the app presents
    /// a consistent dark look regardless of system appearance.
    private enum PaletteLight {
        // Brand / highlight
        static let brand = Color(hex: "#FBBF24") // amber-400
        static let brandEmphasis = Color(hex: "#F59E0B") // amber-500
        // Surfaces
        static let bg = Color(hex: "#020617") // deep slate (new dark baseline)
        static let surface = Color(hex: "#1E293B") // slate-800
        static let surfaceSubtle = Color(hex: "#334155") // slate-700
        static let border = Color(hex: "#475569") // slate-600
        static let formSurface = Color(hex: "#0F1B33") // deep navy
        static let formBorder = Color(hex: "#29415F") // muted navy
        // App chrome (nav/tab bars) - 95% opaque
        static let chrome = Color(hex: "#020617").opacity(0.95)
        // Text
        static let text = Color.white
        static let textSecondary = Color(hex: "#CBD5E1") // slate-300
        static let textMuted = Color(hex: "#94A3B8") // slate-400
        static let onBrand = Color.black // readable over amber
        static let onSurface = Color.white
        // Overlays
        static let overlaySoft = Color.white.opacity(0.05)
        static let overlay = Color.white.opacity(0.1)
        static let overlayStrong = Color.white.opacity(0.2)
        // Status
        static let success = Color(hex: "#10B981") // emerald-500
        static let warning = Color(hex: "#F59E0B") // amber-500
        static let danger = Color(hex: "#EF4444") // red-500
        static let info = Color(hex: "#3B82F6") // blue-500
        static let onStatus = Color.white
        // Domain accents
        static let flavorSweet = Color(hex: "#F59E0B") // amber-500
        static let flavorFruity = Color(hex: "#EC4899") // pink-500
        static let flavorSpicy = Color(hex: "#EF4444") // red-500
        static let flavorWoody = Color(hex: "#8B5E3C") // brownish
        static let flavorSmoky = Color(hex: "#94A3B8") // slate-400
        static let flavorFloral = Color(hex: "#8B5CF6") // purple-500
        static let flavorNutty = Color(hex: "#92400E") // amber-800-ish
        static let flavorOther = Color(hex: "#6366F1") // indigo-500
    }

    private enum PaletteDark {
        // Mirror light palette to maintain consistent dark UI
        static let brand = PaletteLight.brand
        static let brandEmphasis = PaletteLight.brandEmphasis
        static let bg = PaletteLight.bg
        static let surface = PaletteLight.surface
        static let surfaceSubtle = PaletteLight.surfaceSubtle
        static let border = PaletteLight.border
        static let formSurface = PaletteLight.formSurface
        static let formBorder = PaletteLight.formBorder
        static let chrome = PaletteLight.chrome
        static let text = PaletteLight.text
        static let textSecondary = PaletteLight.textSecondary
        static let textMuted = PaletteLight.textMuted
        static let onBrand = PaletteLight.onBrand
        static let onSurface = PaletteLight.onSurface
        static let overlaySoft = PaletteLight.overlaySoft
        static let overlay = PaletteLight.overlay
        static let overlayStrong = PaletteLight.overlayStrong
        static let success = PaletteLight.success
        static let warning = PaletteLight.warning
        static let danger = PaletteLight.danger
        static let info = PaletteLight.info
        static let onStatus = PaletteLight.onStatus
        static let flavorSweet = PaletteLight.flavorSweet
        static let flavorFruity = PaletteLight.flavorFruity
        // Slightly lighter red in dark mode for better contrast on slate background
        static let flavorSpicy = Color(hex: "#F87171") // red-400
        static let flavorWoody = PaletteLight.flavorWoody
        static let flavorSmoky = PaletteLight.flavorSmoky
        static let flavorFloral = PaletteLight.flavorFloral
        static let flavorNutty = PaletteLight.flavorNutty
        static let flavorOther = PaletteLight.flavorOther
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
