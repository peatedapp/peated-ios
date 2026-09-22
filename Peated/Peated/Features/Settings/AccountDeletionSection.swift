import PeatedCore
import SwiftUI

/// The danger area in Settings. App Store Review Guideline 5.1.1(v) requires an
/// in-app way to delete the account.
///
/// Before a request it explains what deletion does. While a deletion is pending
/// it shows the date and makes keeping the account the main action. The pending
/// state comes from the signed-in user's `deletionScheduledAt`.
struct AccountDeletionSection: View {
    @ObservedObject private var authManager = AuthenticationManager.shared
    @State private var isConfirming = false
    @State private var isKeeping = false
    @State private var keepError: String?
    @State private var showsKeptConfirmation = false

    var body: some View {
        FormSection("Delete Account") {
            if let scheduledAt = authManager.currentUser?.deletionScheduledAt {
                pendingNotice(scheduledAt: scheduledAt)
            } else {
                explanation
            }
        }
        .sheet(isPresented: $isConfirming) {
            AccountDeletionConfirmationView()
        }
    }

    @ViewBuilder
    private var explanation: some View {
        if showsKeptConfirmation {
            Text("Your account stays. Nothing was deleted.")
                .font(.subheadline)
                .foregroundColor(.text)
                .fixedSize(horizontal: false, vertical: true)
        }

        Text(
            "Deleting your account removes your profile, tastings, reviews, comments, and collections. "
                + "Bottles and catalog edits you added stay, without your name. "
                + "You'll have 24 hours to change your mind."
        )
        .font(.subheadline)
        .foregroundColor(.textSecondary)
        .fixedSize(horizontal: false, vertical: true)

        Button {
            showsKeptConfirmation = false
            isConfirming = true
        } label: {
            HStack {
                Spacer()
                Text("Delete Account")
                    .foregroundColor(.danger)
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .accessibilityIdentifier("deleteAccountButton")
    }

    @ViewBuilder
    private func pendingNotice(scheduledAt: Date) -> some View {
        Text("Deletion scheduled")
            .font(.headline)
            .foregroundColor(.text)

        Text(
            "Your account will be deleted on "
                + scheduledAt.formatted(date: .abbreviated, time: .shortened)
                + ". Until then everything works as usual, and we've emailed you a confirmation."
        )
        .font(.subheadline)
        .foregroundColor(.textSecondary)
        .fixedSize(horizontal: false, vertical: true)

        if let keepError {
            Text(keepError)
                .font(.caption)
                .foregroundColor(.danger)
                .fixedSize(horizontal: false, vertical: true)
        }

        Button(action: keepAccount) {
            Group {
                if isKeeping {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .onBrand))
                } else {
                    Text("Keep My Account")
                        .fontWeight(.semibold)
                        .foregroundColor(.onBrand)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(Color.brand)
            .cornerRadius(12)
        }
        .disabled(isKeeping)
        .accessibilityIdentifier("keepAccountButton")
    }

    private func keepAccount() {
        Task {
            isKeeping = true
            keepError = nil
            do {
                try await authManager.cancelAccountDeletion()
                showsKeptConfirmation = true
            } catch {
                Telemetry.capture(error, feature: "account", operation: "cancel_deletion")
                keepError = error.localizedDescription
            }
            isKeeping = false
        }
    }
}
