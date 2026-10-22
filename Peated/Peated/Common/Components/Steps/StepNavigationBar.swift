import SwiftUI

/// The Back and primary-action bar along the bottom of a multi-step sheet.
struct StepNavigationBar<Primary: View>: View {
    /// Nil hides Back, as on the first step.
    var onBack: (() -> Void)?
    var backIdentifier: String?
    @ViewBuilder let primary: Primary

    var body: some View {
        HStack(spacing: 16) {
            if let onBack {
                Button(action: onBack) {
                    HStack {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14))
                            .accessibilityHidden(true)
                        Text("Back")
                    }
                    .font(.body)
                    .foregroundColor(.brand)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .accessibilityIdentifier(backIdentifier ?? "")
            }

            Spacer()

            primary
        }
        .padding()
        .overlay(
            Rectangle()
                .fill(Color.formBorder)
                .frame(height: 0.5),
            alignment: .top
        )
    }
}
