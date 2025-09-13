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

// MARK: - Cream Theme (Default)
struct CreamTheme: AppTheme {
  private struct PaletteLight {
    static let brand = Color(hex: "#5D4E32")
    static let brandEmphasis = Color(hex: "#4A3D28")
    static let bg = Color(hex: "#FDF3DA")
    static let surface = Color(hex: "#FFF9ED")
    static let surfaceSubtle = Color(hex: "#F9EED4")
    static let border = Color(hex: "#D7C6A5")
    static let text = Color(hex: "#1F1B16")
    static let textSecondary = Color(hex: "#5D4E32")
    static let textMuted = Color(hex: "#7A6A4E")
    static let onBrand = Color.white
    static let onSurface = Color(hex: "#1F1B16")
    static let overlaySoft = Color.black.opacity(0.15)
    static let overlay = Color.black.opacity(0.3)
    static let overlayStrong = Color.black.opacity(0.6)
    static let success = Color(hex: "#10B981")
    static let warning = Color(hex: "#F59E0B")
    static let danger  = Color(hex: "#EF4444")
    static let info    = Color(hex: "#3B82F6")
    static let onStatus = Color.white
    // Domain accents
    static let flavorSweet = Color(hex: "#F59E0B") // amber
    static let flavorFruity = Color(hex: "#EC4899") // pink
    static let flavorSpicy  = Color(hex: "#EF4444") // red
    static let flavorWoody  = Color(hex: "#8B5E3C") // brown
    static let flavorSmoky  = Color(hex: "#6B7280") // gray
    static let flavorFloral = Color(hex: "#8B5CF6") // purple
    static let flavorNutty  = Color(hex: "#92400E") // brownish
    static let flavorOther  = Color(hex: "#6366F1") // indigo
  }
  private struct PaletteDark {
    static let brand = Color(hex: "#E8D7B6")
    static let brandEmphasis = Color(hex: "#F5E8C9")
    static let bg = Color(hex: "#1C1A16")
    static let surface = Color(hex: "#26231D")
    static let surfaceSubtle = Color(hex: "#2E2A22")
    static let border = Color(hex: "#4A4437")
    static let text = Color(hex: "#F7F3EA")
    static let textSecondary = Color(hex: "#D7C6A5")
    static let textMuted = Color(hex: "#B9A98B")
    static let onBrand = Color.black
    static let onSurface = Color(hex: "#F7F3EA")
    static let overlaySoft = Color.white.opacity(0.12)
    static let overlay = Color.white.opacity(0.25)
    static let overlayStrong = Color.white.opacity(0.5)
    static let success = Color(hex: "#34D399")
    static let warning = Color(hex: "#FBBF24")
    static let danger  = Color(hex: "#F87171")
    static let info    = Color(hex: "#60A5FA")
    static let onStatus = Color.black
    // Domain accents (keep similar hues)
    static let flavorSweet = Color(hex: "#F59E0B")
    static let flavorFruity = Color(hex: "#EC4899")
    static let flavorSpicy  = Color(hex: "#F87171")
    static let flavorWoody  = Color(hex: "#A4714A")
    static let flavorSmoky  = Color(hex: "#9CA3AF")
    static let flavorFloral = Color(hex: "#A78BFA")
    static let flavorNutty  = Color(hex: "#B45309")
    static let flavorOther  = Color(hex: "#818CF8")
  }

  private func dynamic(_ light: Color, _ dark: Color) -> Color {
    #if os(iOS)
    return Color(UIColor { $0.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light) })
    #else
    return light
    #endif
  }

  // Brand
  var brand: Color { dynamic(PaletteLight.brand, PaletteDark.brand) }
  var brandEmphasis: Color { dynamic(PaletteLight.brandEmphasis, PaletteDark.brandEmphasis) }
  var onBrand: Color { dynamic(PaletteLight.onBrand, PaletteDark.onBrand) }
  // Surfaces
  var background: Color { dynamic(PaletteLight.bg, PaletteDark.bg) }
  var surface: Color { dynamic(PaletteLight.surface, PaletteDark.surface) }
  var surfaceSubtle: Color { dynamic(PaletteLight.surfaceSubtle, PaletteDark.surfaceSubtle) }
  var border: Color { dynamic(PaletteLight.border, PaletteDark.border) }
  // Text
  var text: Color { dynamic(PaletteLight.text, PaletteDark.text) }
  var textSecondary: Color { dynamic(PaletteLight.textSecondary, PaletteDark.textSecondary) }
  var textMuted: Color { dynamic(PaletteLight.textMuted, PaletteDark.textMuted) }
  var onSurface: Color { dynamic(PaletteLight.onSurface, PaletteDark.onSurface) }
  // Overlays
  var overlaySoft: Color { dynamic(PaletteLight.overlaySoft, PaletteDark.overlaySoft) }
  var overlay: Color { dynamic(PaletteLight.overlay, PaletteDark.overlay) }
  var overlayStrong: Color { dynamic(PaletteLight.overlayStrong, PaletteDark.overlayStrong) }
  // Status
  var success: Color { dynamic(PaletteLight.success, PaletteDark.success) }
  var warning: Color { dynamic(PaletteLight.warning, PaletteDark.warning) }
  var danger: Color { dynamic(PaletteLight.danger, PaletteDark.danger) }
  var info: Color { dynamic(PaletteLight.info, PaletteDark.info) }
  var onStatus: Color { dynamic(PaletteLight.onStatus, PaletteDark.onStatus) }
  // Domain accents
  var flavorSweet: Color { dynamic(PaletteLight.flavorSweet, PaletteDark.flavorSweet) }
  var flavorFruity: Color { dynamic(PaletteLight.flavorFruity, PaletteDark.flavorFruity) }
  var flavorSpicy: Color { dynamic(PaletteLight.flavorSpicy, PaletteDark.flavorSpicy) }
  var flavorWoody: Color { dynamic(PaletteLight.flavorWoody, PaletteDark.flavorWoody) }
  var flavorSmoky: Color { dynamic(PaletteLight.flavorSmoky, PaletteDark.flavorSmoky) }
  var flavorFloral: Color { dynamic(PaletteLight.flavorFloral, PaletteDark.flavorFloral) }
  var flavorNutty: Color { dynamic(PaletteLight.flavorNutty, PaletteDark.flavorNutty) }
  var flavorOther: Color { dynamic(PaletteLight.flavorOther, PaletteDark.flavorOther) }
}

// MARK: - Theme Manager
final class ThemeManager: ObservableObject {
  static let shared = ThemeManager()
  @Published var theme: AppTheme = CreamTheme()
}

// MARK: - Environment Support
private struct AppThemeKey: EnvironmentKey {
  static let defaultValue: AppTheme = ThemeManager.shared.theme
}

extension EnvironmentValues {
  var appTheme: AppTheme {
    get { self[AppThemeKey.self] }
    set { self[AppThemeKey.self] = newValue }
  }
}

extension View {
  func appTheme(_ theme: AppTheme) -> some View { environment(\.appTheme, theme) }
}

// Internal provider used by Color tokens to resolve current theme.
enum ThemeProvider {
  static var current: AppTheme { ThemeManager.shared.theme }
}
