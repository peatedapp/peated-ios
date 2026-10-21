import SwiftUI

/// The title and one-line description at the top of a sign-in or sign-up step.
struct AuthPanelHeader: View {
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Text(title)
                .font(.peatedPageTitleCompact)
                .tracking(DesignSystem.Tracking.pageTitleCompact)
                .fontWeight(.bold)
                .foregroundColor(.text)
                .accessibilityAddTraits(.isHeader)

            Text(description)
                .font(.peatedBody)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, DesignSystem.Spacing.xLarge)
    }
}
