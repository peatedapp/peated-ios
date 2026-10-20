import SwiftUI

/// An inline error on a sign-in or sign-up step, in place of an alert.
/// VoiceOver announces the message when it appears.
struct AuthNotice: View {
    let message: String?

    var body: some View {
        if let message {
            Text(message)
                .font(.peatedBody)
                .fontWeight(.semibold)
                .foregroundColor(.brandEmphasis)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(DesignSystem.Spacing.large)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                        .strokeBorder(Color.brandTint, lineWidth: DesignSystem.Border.thin)
                )
                .padding(.bottom, DesignSystem.Spacing.medium)
                .onAppear { AccessibilityNotification.Announcement(message).post() }
                .onChange(of: message) { _, newMessage in
                    AccessibilityNotification.Announcement(newMessage).post()
                }
        }
    }
}
