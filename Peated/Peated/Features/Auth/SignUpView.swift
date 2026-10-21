import PeatedCore
import SwiftUI
import UIKit

/// Creates an account. Mirrors the peated.com sign-up panel: Apple or Google,
/// or an email and username with a new passkey instead of a password.
struct SignUpView: View {
    let onSignUpSuccess: (User) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var username = ""
    @State private var email = ""
    @State private var acceptedTerms = false
    @State private var isLoading = false
    @State private var error: String?
    /// Set when the server says the email already has an account, which
    /// replaces the form with ways to sign in to that account.
    @State private var takenEmail: String?
    @State private var legalDocument: LegalDocument?
    @State private var passkeyCreator = AuthorizationRequester<PasskeyRegistration>()
    @State private var passkeySignIn = AuthorizationRequester<PasskeyAssertion>()

    private let authManager = AuthenticationManager.shared

    var body: some View {
        ZStack {
            Color.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    PeatedLogo(height: 32)
                        .accessibilityLabel("Peated")
                        .padding(.bottom, DesignSystem.Spacing.xxxLarge)

                    if takenEmail != nil {
                        takenEmailPanel
                    } else {
                        signUpPanel
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.xLarge)
                .padding(.top, DesignSystem.Spacing.large)
                .padding(.bottom, DesignSystem.Spacing.xxxLarge)
                .frame(maxWidth: 520, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationBarTitleDisplayMode(.inline)
        .tint(.brandEmphasis)
        .overlay(loadingOverlay)
        .sheet(item: $legalDocument) { document in
            SafariView(url: document.url)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    // MARK: - Sign-up Panel

    private var signUpPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            AuthPanelHeader(
                title: "Create an account",
                description: "Two fields and a passkey. No password to remember."
            )

            AuthNotice(message: error)

            VStack(spacing: 6) {
                AppleSignInButton(title: "Sign up with Apple") { result in
                    switch result {
                    case let .success(credential):
                        handleAppleSignUp(credential)
                    case let .failure(error):
                        self.error = error.localizedDescription
                    }
                }

                Button(action: handleGoogleSignUp) {
                    Label {
                        Text("Sign up with Google")
                    } icon: {
                        Image("GoogleLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 17, height: 17)
                    }
                }
                .buttonStyle(.authTonal)
            }
            .disabled(isLoading)

            AuthDivider(label: "or")
                .padding(.vertical, DesignSystem.Spacing.xLarge)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.medium) {
                TextInput(
                    label: "Email",
                    placeholder: "you@example.com",
                    text: $email,
                    keyboard: .emailAddress,
                    contentType: .emailAddress,
                    submitLabel: .next,
                    autocorrection: false,
                    capitalization: .never,
                    identifier: AccessibilityID.Auth.email
                )

                TextInput(
                    label: "Username",
                    placeholder: "caskstrength_k",
                    text: $username,
                    keyboard: .asciiCapable,
                    contentType: .username,
                    submitLabel: .done,
                    autocorrection: false,
                    capitalization: .never,
                    helper: "Shown on every tasting you log.",
                    identifier: AccessibilityID.Auth.username
                )

                termsRow
            }
            .padding(.bottom, DesignSystem.Spacing.large)

            Button(action: handlePasskeySignUp) {
                Label("Create account with a passkey", systemImage: "key")
            }
            .buttonStyle(.authAccent)
            .disabled(!canCreateAccount)
            .accessibilityIdentifier(AccessibilityID.Auth.createAccount)

            AuthDivider()
                .padding(.vertical, 26)

            HStack(spacing: DesignSystem.Spacing.small) {
                Text("Already have an account?")
                    .font(.peatedMetadata)
                    .foregroundColor(.textMuted)
                Button { dismiss() } label: {
                    AuthLinkLabel(title: "Sign in")
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// The App Store requires the Privacy Policy link here as well as the Terms.
    /// The sentence is one wrapping text with inline links, which open in the
    /// in-app browser instead of Safari.
    private var termsRow: some View {
        HStack(alignment: .center, spacing: 0) {
            Button {
                acceptedTerms.toggle()
            } label: {
                Image(systemName: acceptedTerms ? "checkmark.square.fill" : "square")
                    .font(.system(size: 20))
                    .foregroundColor(acceptedTerms ? .brand : .textMuted)
                    // A 44-point hit target, with the box flush with the fields above.
                    .frame(minWidth: DesignSystem.ControlHeight.standard,
                           minHeight: DesignSystem.ControlHeight.standard,
                           alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("I agree to the Terms of Service and Privacy Policy")
            .accessibilityValue(acceptedTerms ? "Checked" : "Not checked")
            .accessibilityAddTraits(.isToggle)
            .accessibilityIdentifier(AccessibilityID.Auth.termsToggle)

            Text(termsSentence)
                .font(.peatedMetadata)
                .foregroundColor(.textSecondary)
                .tint(.brandEmphasis)
                .fixedSize(horizontal: false, vertical: true)
                .environment(\.openURL, OpenURLAction { url in
                    guard let document = LegalDocument.allCases.first(where: { $0.url == url }) else {
                        return .systemAction
                    }
                    legalDocument = document
                    return .handled
                })
        }
    }

    private var termsSentence: AttributedString {
        let markdown = "I agree to the [Terms of Service](\(LegalDocument.terms.url)) "
            + "and [Privacy Policy](\(LegalDocument.privacy.url))."
        return (try? AttributedString(markdown: markdown))
            ?? AttributedString("I agree to the Terms of Service and Privacy Policy.")
    }

    private var canCreateAccount: Bool {
        !trimmedUsername.isEmpty && !trimmedEmail.isEmpty && acceptedTerms && !isLoading
    }

    private var trimmedUsername: String {
        username.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Taken Email Panel

    private var takenEmailPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            AuthPanelHeader(
                title: "That email already has an account",
                description: "Sign in with an existing passkey, choose another method, or recover access."
            )

            AuthNotice(message: error)

            VStack(spacing: 6) {
                Button(action: handlePasskeySignIn) {
                    Label("Continue with a passkey", systemImage: "key")
                }
                .buttonStyle(.authTonal)

                Button { dismiss() } label: {
                    Text("Other sign-in options")
                }
                .buttonStyle(.authTonal)
            }
            .disabled(isLoading)

            AuthDivider()
                .padding(.vertical, 26)

            HStack(spacing: DesignSystem.Spacing.small) {
                Link(destination: PeatedWebURL.recoverAccount) {
                    AuthLinkLabel(title: "Recover your account")
                }
                Text("·")
                    .font(.peatedMetadata)
                    .foregroundColor(.textMuted)
                    .accessibilityHidden(true)
                Button {
                    error = nil
                    takenEmail = nil
                } label: {
                    AuthLinkLabel(title: "Use a different email")
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Loading Overlay

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

    private func handlePasskeySignUp() {
        guard canCreateAccount else { return }
        let email = trimmedEmail
        Task {
            isLoading = true
            error = nil
            defer { isLoading = false }
            do {
                let user = try await authManager.registerWithPasskey(
                    username: trimmedUsername,
                    email: email,
                    tosAccepted: acceptedTerms
                ) { challenge in
                    try await createPasskey(for: challenge)
                }
                if let user {
                    onSignUpSuccess(user)
                }
            } catch let AuthError.registrationConflict(field: .email, message) {
                error = message
                takenEmail = email
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    private func createPasskey(for challenge: PasskeyRegistrationChallenge) async throws -> PasskeyRegistration? {
        #if DEBUG
            if UITestHarness.isActive {
                return UITestHarness.passkeyRegistration
            }
        #endif
        return try await passkeyCreator.requestPasskeyRegistration(for: challenge)
    }

    private func handlePasskeySignIn() {
        Task {
            isLoading = true
            error = nil
            defer { isLoading = false }
            do {
                let user = try await authManager.loginWithPasskey { challenge in
                    try await passkeySignIn.requestPasskey(for: challenge)
                }
                if let user {
                    onSignUpSuccess(user)
                }
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    private func handleAppleSignUp(_ credential: AppleSignInCredential) {
        // The backend links or creates the account on the first successful Apple auth.
        Task {
            isLoading = true
            error = nil
            defer { isLoading = false }
            do {
                let user = try await authManager.loginWithApple(
                    identityToken: credential.identityToken,
                    fullName: credential.fullName
                )
                onSignUpSuccess(user)
            } catch {
                self.error = error.localizedDescription
            }
        }
    }

    private func handleGoogleSignUp() {
        // The backend creates the account on the first successful Google auth.
        Task {
            isLoading = true
            error = nil
            defer { isLoading = false }
            do {
                let user = try await authManager.loginWithGoogle()
                onSignUpSuccess(user)
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
}
