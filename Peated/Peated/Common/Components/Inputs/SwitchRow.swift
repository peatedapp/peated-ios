import SwiftUI

/// A switch with a title and a line that says what turning it on means.
struct SwitchRow: View {
    let title: String
    let description: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xSmall) {
                Text(title)
                    .font(.peatedInput)
                    .foregroundColor(.text)
                Text(description)
                    .font(.peatedMetadata)
                    .foregroundColor(.textSecondary)
            }
        }
        .tint(.brand)
    }
}
