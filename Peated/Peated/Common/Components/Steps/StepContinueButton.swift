import SwiftUI

/// The pill-shaped primary action in a `StepNavigationBar`.
struct StepContinueButton: View {
    let title: String
    var showsChevron = true
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .accessibilityHidden(true)
                }
            }
            .font(.body)
            .fontWeight(.medium)
            // A solid muted surface keeps the disabled label readable; a
            // translucent brand fill does not meet the contrast minimum.
            .foregroundColor(isEnabled ? .onBrand : .textSecondary)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(isEnabled ? Color.brand : Color.formSurface)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isEnabled ? Color.clear : Color.formBorder, lineWidth: 1)
            )
            .cornerRadius(20)
        }
        .disabled(!isEnabled)
    }
}
