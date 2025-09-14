import SwiftUI

/// Subtle app-wide background that prevents flat, solid fills.
///
/// Mimics the website’s slight top-left glow using layered, very low-opacity
/// gradients over the theme `Color.background`. Designed to be unobtrusive and
/// work across dark mode UI.
struct ScreenBackground: View {
  var body: some View {
    ZStack {
      // Base background color from theme
      Color.background

      // Subtle diagonal lightening from top-left (dark) to bottom-right (light)
      // Keep it gentle so background reads as nearly solid.
      LinearGradient(
        colors: [
          .clear,                    // preserve #0F172A at top-left
          Color.white.opacity(0.06)  // dialed back lift toward bottom-right
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    }
    .ignoresSafeArea()
  }
}

extension View {
  /// Applies the unified subtle gradient background behind the view.
  func screenBackground() -> some View {
    self.background(ScreenBackground())
  }
}
