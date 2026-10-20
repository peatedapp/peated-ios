import SwiftUI

/// A hairline between sections of a sign-in or sign-up step, with an optional
/// centered label such as "or".
struct AuthDivider: View {
    var label: String?

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            rule
            if let label {
                Text(label)
                    .font(.peatedMetadata)
                    .foregroundColor(.textMuted)
                rule
            }
        }
        .accessibilityHidden(true)
    }

    private var rule: some View {
        Rectangle()
            .fill(Color.border)
            .frame(height: DesignSystem.Border.thin)
    }
}
