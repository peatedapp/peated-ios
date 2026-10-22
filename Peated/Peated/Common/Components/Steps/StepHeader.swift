import SwiftUI

/// The title and one-line summary at the top of a step. VoiceOver moves to the title when the step changes.
struct StepHeader: View {
    let title: String
    let summary: String
    var isFocused: AccessibilityFocusState<Bool>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Text(title)
                .font(.peatedPageTitleCompact)
                .tracking(DesignSystem.Tracking.pageTitleCompact)
                .foregroundColor(.text)
                .accessibilityAddTraits(.isHeader)
                .accessibilityFocused(isFocused)

            Text(summary)
                .font(.peatedBody)
                .foregroundColor(.textSecondary)
        }
    }
}
