import SwiftUI

// Centralized text styles to guarantee visual consistency across screens.
struct HeadlineStyle: ViewModifier {
  func body(content: Content) -> some View {
    content
      // Use SwiftUI's semantic headline to ensure consistent
      // SF Text family, metrics, and dynamic type behavior.
      .font(.headline)
      .foregroundColor(.text)
  }
}

extension View {
  func headlineStyle() -> some View { self.modifier(HeadlineStyle()) }
}
