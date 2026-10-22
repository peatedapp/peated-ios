import SwiftUI

/// The "2/5" label in a multi-step sheet's toolbar. VoiceOver reads it as "Step 2 of 5".
struct StepCountLabel: View {
    /// One-based.
    let current: Int
    let total: Int

    var body: some View {
        // The spoken label lives on a wrapper so the visible text keeps its own,
        // shorter label; otherwise the accessibility audit reports it as clipped.
        ZStack {
            Text("\(current)/\(total)")
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(current) of \(total)")
        .accessibilityAddTraits(.isStaticText)
    }
}
