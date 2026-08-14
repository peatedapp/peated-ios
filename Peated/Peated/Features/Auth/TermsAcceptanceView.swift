import PeatedCore
import SwiftUI

struct TermsAcceptanceView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var isAccepting = false
    @State private var error: Error?

    var onAccepted: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: "doc.text")
                .font(.system(size: 60))
                .foregroundColor(.brand)

            // Title
            Text("Terms of Service Update")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            // Message
            Text("We've updated our Terms of Service. Please review and accept to continue using Peated.")
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Error message
            if let error {
                Text(error.localizedDescription)
                    .font(.caption)
                    .foregroundColor(.danger)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            // Action buttons
            VStack(spacing: 16) {
                // Accept button
                Button(action: acceptTerms) {
                    if isAccepting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .onBrand))
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.brand)
                            .cornerRadius(12)
                    } else {
                        Text("Accept Terms")
                            .fontWeight(.semibold)
                            .foregroundColor(.onBrand)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.brand)
                            .cornerRadius(12)
                    }
                }
                .disabled(isAccepting)

                // View terms link
                Link(destination: URL(string: "https://peated.com/terms")!) {
                    Text("View Terms of Service")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }

                // Logout option
                Button(action: logout) {
                    Text("Log Out")
                        .font(.subheadline)
                        .foregroundColor(.danger)
                }
                .disabled(isAccepting)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.background)
    }

    private func acceptTerms() {
        isAccepting = true
        error = nil

        Task {
            do {
                try await authManager.acceptTerms()
                await MainActor.run {
                    isAccepting = false
                    onAccepted()
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    isAccepting = false
                }
            }
        }
    }

    private func logout() {
        Task {
            await authManager.logout()
        }
    }
}

#Preview {
    TermsAcceptanceView(onAccepted: {})
        .environmentObject(AuthenticationManager.shared)
}
