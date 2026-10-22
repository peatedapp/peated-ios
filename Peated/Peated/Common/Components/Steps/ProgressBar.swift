import SwiftUI

/// The thin progress line at the top of a multi-step sheet.
struct ProgressBar: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.border.opacity(0.3))
                    .frame(height: 4)

                // Progress
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.brand)
                    .frame(
                        width: geometry.size.width * (CGFloat(currentStep) / CGFloat(totalSteps)),
                        height: 4
                    )
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
        .frame(height: 4)
        // The step count label speaks the progress.
        .accessibilityHidden(true)
    }
}
