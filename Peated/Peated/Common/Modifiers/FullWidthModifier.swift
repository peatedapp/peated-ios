import SwiftUI

struct FullWidthModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity)
    }
}

extension View {
    func fullWidth() -> some View {
        modifier(FullWidthModifier())
    }
}

