import SwiftUI

/// Standardizes our navigation bar chrome across the app. The bar follows the
/// system color scheme, like the rest of the app.
struct NavigationChrome: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbarBackground(Color.chrome, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}

extension View {
    func navigationChrome() -> some View {
        modifier(NavigationChrome())
    }
}
