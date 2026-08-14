import SwiftUI

/// Standardizes our navigation bar chrome across the app and prevents
/// accidental tint leaks (e.g., back button appearing in brand/amber).
struct NavigationChrome: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbarBackground(Color.chrome, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            // Ensure nav items (back chevron/text) use our text color (white)
            .tint(.text)
    }
}

extension View {
    func navigationChrome() -> some View {
        modifier(NavigationChrome())
    }
}
