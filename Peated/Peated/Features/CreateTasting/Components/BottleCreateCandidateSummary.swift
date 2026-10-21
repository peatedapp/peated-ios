import SwiftUI

/// Says that existing bottles may match the draft and offers a review. Wording matches the web form.
struct BottleCreateCandidateSummary: View {
    let count: Int
    var loading = false
    /// True after a review, so later matches read as "more" bottles.
    var newSinceReview = false
    let onReview: () -> Void

    private var bottleCount: String {
        "\(count) \(newSinceReview ? "more " : "")\(count == 1 ? "bottle" : "bottles")"
    }

    private var status: String {
        "\(bottleCount) may match this one."
    }

    var body: some View {
        HStack(spacing: 8) {
            Text(status)
                .font(.peatedMetadata)
                .foregroundColor(.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            Button("Review", action: onReview)
                .font(.peatedBody.weight(.medium))
                .foregroundColor(.brand)
                .disabled(loading)
                .accessibilityLabel("Review \(bottleCount) that may match this one")
        }
        .frame(minHeight: 44)
        .padding(.leading, 12)
        .padding(.trailing, 8)
        .background(Color.brandTint)
        .cornerRadius(DesignSystem.CornerRadius.medium)
        .onChange(of: status, initial: true) { _, status in
            // The web marks this line as a polite live region.
            AccessibilityNotification.Announcement(status).post()
        }
    }
}
