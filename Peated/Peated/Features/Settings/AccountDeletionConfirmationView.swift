import PeatedCore
import SwiftUI

/// Final confirmation before an account deletion is scheduled.
///
/// Accounts that signed in with Apple confirm through a fresh Sign in with Apple
/// prompt after tapping the button. Its authorization code lets the server
/// revoke the Apple grant now, which Apple requires. Cancelling that prompt
/// leaves the sheet open with nothing changed. The sheet closes only after the
/// server has scheduled the deletion.
struct AccountDeletionConfirmationView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var authManager = AuthenticationManager.shared
    @State private var appleRequester = AppleAuthorizationRequester()
    @State private var isDeleting = false
    @State private var error: String?

    private var confirmsWithApple: Bool {
        authManager.signInProvider == .apple
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "person.crop.circle.badge.xmark")
                    .font(.system(size: 60))
                    .foregroundColor(.danger)
                    .accessibilityHidden(true)

                Text("Delete your account?")
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(
                    "We'll delete your account in 24 hours. You can cancel from Settings until then. "
                        + "After that, your profile, tastings, reviews, comments, and collections are gone for good."
                )
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

                if confirmsWithApple {
                    Text(
                        "You'll confirm with your Apple ID so Peated is also removed "
                            + "from your Sign in with Apple settings."
                    )
                    .font(.footnote)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                }

                if let error {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.danger)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                Spacer()

                Button(action: deleteAccount) {
                    Group {
                        if isDeleting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .onStatus))
                        } else {
                            Text("Delete My Account")
                                .fontWeight(.semibold)
                                .foregroundColor(.onStatus)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 50)
                    .background(Color.danger)
                    .cornerRadius(12)
                }
                .disabled(isDeleting)
                .accessibilityIdentifier("confirmDeleteAccountButton")
                .padding(.horizontal, 32)
                .padding(.bottom, 24)
            }
            .navigationChrome()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isDeleting)
                }
            }
        }
        .screenBackground()
        .interactiveDismissDisabled(isDeleting)
    }

    private func deleteAccount() {
        Task {
            isDeleting = true
            error = nil
            defer { isDeleting = false }
            do {
                var appleAuthorizationCode: String?
                if confirmsWithApple {
                    guard let credential = try await appleRequester.request() else { return }
                    appleAuthorizationCode = credential.authorizationCode
                }
                try await authManager.requestAccountDeletion(appleAuthorizationCode: appleAuthorizationCode)
                dismiss()
            } catch {
                Telemetry.capture(error, feature: "account", operation: "request_deletion")
                self.error = error.localizedDescription
            }
        }
    }
}

#Preview {
    AccountDeletionConfirmationView()
}
