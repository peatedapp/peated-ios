import SwiftUI

/// The label of an inline brand-colored link on the auth screens, such as
/// "Create one" or "Sign in".
struct AuthLinkLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.peatedInteractiveSmall)
            .foregroundColor(.brandEmphasis)
            // Keep the bare text link at the 44-point minimum hit target.
            .frame(minHeight: DesignSystem.ControlHeight.standard)
            .contentShape(Rectangle())
    }
}
