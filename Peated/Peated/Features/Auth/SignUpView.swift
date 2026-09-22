import PeatedCore
import SwiftUI
import UIKit

struct SignUpView: View {
    let onSignUpSuccess: (User) -> Void

    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var acceptedTerms = false
    @State private var isLoading = false
    @State private var error: String?
    @State private var legalDocument: LegalDocument?

    private let authManager = AuthenticationManager.shared

    var body: some View {
        ZStack {
            Color.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                        .padding(.top, 60)

                    VStack(spacing: 12) {
                        appleSignUpButton
                        googleSignUpButton
                    }
                    .padding(.horizontal)

                    divider
                        .padding(.horizontal)

                    formFields
                        .padding(.horizontal)

                    termsRow
                        .padding(.horizontal)

                    signUpButton
                        .padding(.horizontal)
                        .padding(.top, 8)

                    Spacer(minLength: 40)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationTitle("Create account")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Sign Up Failed", isPresented: Binding(get: { error != nil }, set: {
            if !$0 {
                error = nil
            }
        })) {
            Button("OK") { error = nil }
        } message: {
            Text(error ?? "An error occurred")
        }
        .overlay(loadingOverlay)
        .sheet(item: $legalDocument) { document in
            SafariView(url: document.url)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 8) {
            PeatedLogo(height: 60)
            Text("Join Peated")
                .font(.peatedPageTitleCompact)
                .tracking(DesignSystem.Tracking.pageTitleCompact)
                .fontWeight(.bold)
                .foregroundColor(.text)
            Text("Track and share your whisky journey")
                .font(.peatedProse)
                .foregroundColor(.textSecondary)
        }
    }

    private var divider: some View {
        HStack {
            Rectangle().fill(Color.border).frame(height: 1)
            Text("OR").font(.peatedMetadata).foregroundColor(.textMuted).padding(.horizontal, 16)
            Rectangle().fill(Color.border).frame(height: 1)
        }
    }

    private var formFields: some View {
        VStack(spacing: 16) {
            TextInput(
                label: "Username",
                placeholder: "Username",
                text: $username,
                keyboard: .asciiCapable,
                submitLabel: .next,
                autocorrection: false,
                capitalization: .never,
                identifier: AccessibilityID.Auth.username
            )

            TextInput(
                label: "Email",
                placeholder: "Email",
                text: $email,
                keyboard: .emailAddress,
                submitLabel: .next,
                autocorrection: false,
                capitalization: .never,
                identifier: AccessibilityID.Auth.email
            )

            PasswordInput(
                label: "Password",
                placeholder: "Password",
                text: $password,
                submitLabel: .done,
                onSubmit: { handleEmailSignUp() },
                identifier: AccessibilityID.Auth.password
            )
        }
    }

    private var termsRow: some View {
        HStack(alignment: .center, spacing: 10) {
            Toggle(isOn: $acceptedTerms) { EmptyView() }
                .toggleStyle(.switch)
                .tint(.brand)
                .labelsHidden()
                .accessibilityLabel("I agree to the Terms of Service and Privacy Policy")
                .accessibilityIdentifier(AccessibilityID.Auth.termsToggle)

            HStack(spacing: 4) {
                Text("I agree to the")
                    .foregroundColor(.textSecondary)
                legalLink("Terms of Service", document: .terms, identifier: AccessibilityID.Auth.termsLink)
                Text("and")
                    .foregroundColor(.textSecondary)
                legalLink("Privacy Policy", document: .privacy, identifier: AccessibilityID.Auth.privacyLink)
            }
        }
        .font(.peatedMetadata)
    }

    private func legalLink(_ title: String, document: LegalDocument, identifier: String) -> some View {
        Button {
            legalDocument = document
        } label: {
            Text(title)
                .foregroundColor(.brand)
                .underline()
                // Keep the inline text link at the 44-point minimum hit target.
                .frame(minHeight: DesignSystem.ControlHeight.standard)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(identifier)
    }

    private var signUpButton: some View {
        Button(action: handleEmailSignUp) {
            Text("Create Account")
                .font(.peatedInteractive)
                .foregroundColor(.onBrand)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isPrimaryEnabled ? Color.brand : Color.brand.opacity(0.5))
                .cornerRadius(12)
        }
        .disabled(!isPrimaryEnabled || isLoading)
        .accessibilityIdentifier(AccessibilityID.Auth.createAccount)
    }

    private var isPrimaryEnabled: Bool {
        !username.isEmpty && !email.isEmpty && !password.isEmpty && acceptedTerms && !isLoading
    }

    private var appleSignUpButton: some View {
        AppleSignInButton(label: .continue) { result in
            switch result {
            case let .success(credential):
                handleAppleSignUp(credential)
            case let .failure(error):
                self.error = error.localizedDescription
            }
        }
        .disabled(isLoading)
    }

    private var googleSignUpButton: some View {
        Button(action: handleGoogleSignUp) {
            HStack(spacing: 12) {
                Image(systemName: "g.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.onBrand)
                if isLoading {
                    ProgressView().progressViewStyle(.circular)
                        .tint(.onBrand)
                } else {
                    Text("Continue with Google")
                        .font(.peatedInteractive)
                        .foregroundColor(.onBrand)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isLoading ? Color.brand.opacity(0.6) : Color.brand)
            .cornerRadius(12)
            .animation(.easeInOut(duration: 0.1), value: isLoading)
        }
        .disabled(isLoading)
    }

    @ViewBuilder
    private var loadingOverlay: some View {
        if isLoading {
            Color.overlayStrong
                .ignoresSafeArea()
                .overlay(
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .onStatus))
                        .scaleEffect(1.5)
                )
        }
    }

    // MARK: - Actions

    private func handleEmailSignUp() {
        guard isPrimaryEnabled else { return }
        Task {
            isLoading = true
            error = nil
            do {
                let user = try await authManager.register(
                    username: username,
                    email: email,
                    password: password,
                    tosAccepted: acceptedTerms
                )
                await MainActor.run { onSignUpSuccess(user) }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func handleAppleSignUp(_ credential: AppleSignInCredential) {
        // The backend links or creates the account on the first successful Apple auth.
        Task {
            isLoading = true
            error = nil
            do {
                let user = try await authManager.loginWithApple(
                    identityToken: credential.identityToken,
                    fullName: credential.fullName
                )
                await MainActor.run { onSignUpSuccess(user) }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func handleGoogleSignUp() {
        // The backend will create an account on first successful Google auth
        Task {
            isLoading = true
            error = nil
            do {
                let user = try await authManager.loginWithGoogle()
                await MainActor.run { onSignUpSuccess(user) }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}
