import SwiftUI

extension Color {
  // Brand Colors
  static let peatedGold = Color(hex: "#fbbf24")          // Primary accent, toasts, ratings
  static let peatedGoldDark = Color(hex: "#f59e0b")      // Darker variant for pressed states
  
  // Background Colors (Dark Theme)
  static let peatedBackground = Color(hex: "#020617")     // Main background (slate-950)
  static let peatedSurface = Color(hex: "#0f172a")        // Elevated surfaces (slate-900)
  static let peatedSurfaceLight = Color(hex: "#1e293b")   // Cards, cells (slate-800)
  static let peatedSurfaceSubtle = Color(hex: "#2d3748")  // Subtle card backgrounds (slate-700 with opacity)
  
  // Border Colors
  static let peatedBorder = Color(hex: "#334155")         // Default borders (slate-700)
  static let peatedBorderLight = Color(hex: "#475569")    // Hover/focus borders (slate-600)
  
  // Text Colors
  static let peatedTextPrimary = Color.white
  static let peatedTextSecondary = Color.white.opacity(0.7)
  static let peatedTextMuted = Color.white.opacity(0.5)
  
  // Semantic Colors
  static let peatedSuccess = Color(hex: "#10b981")        // Green for success
  static let peatedError = Color(hex: "#ef4444")          // Red for errors
  static let peatedWarning = Color(hex: "#f59e0b")        // Amber for warnings
  static let peatedInfo = Color(hex: "#3b82f6")           // Blue for info
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