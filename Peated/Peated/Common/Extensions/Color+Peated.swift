import SwiftUI

// Semantic tokens resolve through the current AppTheme.
extension Color {
  // Brand
  static var brand: Color { ThemeProvider.current.brand }
  static var brandEmphasis: Color { ThemeProvider.current.brandEmphasis }
  static var onBrand: Color { ThemeProvider.current.onBrand }
  // Surfaces
  static var background: Color { ThemeProvider.current.background }
  static var surface: Color { ThemeProvider.current.surface }
  static var surfaceSubtle: Color { ThemeProvider.current.surfaceSubtle }
  static var border: Color { ThemeProvider.current.border }
  // Text
  static var text: Color { ThemeProvider.current.text }
  static var textSecondary: Color { ThemeProvider.current.textSecondary }
  static var textMuted: Color { ThemeProvider.current.textMuted }
  static var onSurface: Color { ThemeProvider.current.onSurface }
  // Overlays
  static var overlaySoft: Color { ThemeProvider.current.overlaySoft }
  static var overlay: Color { ThemeProvider.current.overlay }
  static var overlayStrong: Color { ThemeProvider.current.overlayStrong }
  // Status
  static var success: Color { ThemeProvider.current.success }
  static var warning: Color { ThemeProvider.current.warning }
  static var danger: Color { ThemeProvider.current.danger }
  static var info: Color { ThemeProvider.current.info }
  static var onStatus: Color { ThemeProvider.current.onStatus }

  // Domain accents (Flavor categories)
  static var flavorSweet: Color { ThemeProvider.current.flavorSweet }
  static var flavorFruity: Color { ThemeProvider.current.flavorFruity }
  static var flavorSpicy: Color { ThemeProvider.current.flavorSpicy }
  static var flavorWoody: Color { ThemeProvider.current.flavorWoody }
  static var flavorSmoky: Color { ThemeProvider.current.flavorSmoky }
  static var flavorFloral: Color { ThemeProvider.current.flavorFloral }
  static var flavorNutty: Color { ThemeProvider.current.flavorNutty }
  static var flavorOther: Color { ThemeProvider.current.flavorOther }

  // No legacy aliases are kept; use semantic tokens above.
}

// Helper extension for hex colors
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
      blue:  Double(b) / 255,
      opacity: Double(a) / 255
    )
  }
}
