import SwiftUI

/// App-wide background that uses a solid dark color from the theme.
/// Removes gradients to keep the UI consistently dark across all screens.
struct ScreenBackground: View {
    var body: some View {
        Color.background
            .ignoresSafeArea()
    }
}

extension View {
    /// Applies the unified subtle gradient background behind the view.
    func screenBackground() -> some View {
        background(ScreenBackground())
    }
}
