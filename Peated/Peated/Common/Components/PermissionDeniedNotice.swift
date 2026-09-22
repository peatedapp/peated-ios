import SwiftUI
import UIKit

/// Inline explanation for a feature the user has switched off in Settings,
/// with the one action that fixes it.
struct PermissionDeniedNotice: View {
    @Environment(\.openURL) private var openURL
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: "exclamationmark.triangle.fill")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.text)

            Text(message)
                .font(.caption)
                .foregroundColor(.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Button("Open Settings") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    openURL(settingsURL)
                }
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .foregroundColor(.brand)
            .frame(minHeight: DesignSystem.ControlHeight.standard)
            .accessibilityIdentifier(AccessibilityID.Permission.openSettings)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.formSurface)
        .cornerRadius(12)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AccessibilityID.Permission.deniedNotice)
    }
}
