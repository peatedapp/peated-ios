import GoogleSignIn
import PeatedCore
import SwiftUI

/// The signed-out landing screen. Mirrors the peated.com sign-in panel: a list
/// of sign-in methods first, and the email form one step in.
struct LoginViewSimple: View {
    let onLoginSuccess: (User) -> Void

    private enum Step {
        case methods
        case email
    }

    @State private var step = Step.methods
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var error: String?
    @FocusState private var isEmailFocused: Bool
    @State private var passkeyRequester = AuthorizationRequester<PasskeyAssertion>()
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let authManager = AuthenticationManager.shared

    var body: some View {
        ZStack {
            Color.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    PeatedLogo(height: 32)
                        .accessibilityLabel("Peated")
                        .padding(.bottom, DesignSystem.Spacing.xxxLarge)

                    switch step {
                    case .methods:
                        methodsPanel
                    case .email:
                        emailPanel
                    }

                    accountLinks
                }
                .padding(.horizontal, DesignSystem.Spacing.xLarge)
                .padding(.top, DesignSystem.Spacing.xxLarge)
                .padding(.bottom, DesignSystem.Spacing.xxxLarge)
                .frame(maxWidth: 520, alignment: .leading)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationBarHidden(true)
        .overlay(loadingOverlay)
        .onChange(of: error) { _, message in
            if let message {
                AccessibilityNotification.Announcement(message).post()
            }
        }
    }

    // MARK: - Panels

    private var methodsPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            panelHeader(title: "Sign in", description: "A passkey is fastest. Email works everywhere.")

            errorNotice

            VStack(spacing: 6) {
                Button(action: handlePasskeySignIn) {
                    Label("Continue with a passkey", systemImage: "key")
                }
                .buttonStyle(.authTonal)

                AppleSignInButton { result in
                    switch result {
                    case let .success(credential):
                        handleAppleSignIn(credential)
                    case let .failure(error):
                        self.error = error.localizedDescription
                    }
                }

                Button(action: handleGoogleSignIn) {
                    Label {
                        Text("Continue with Google")
                    } icon: {
                        Image("GoogleLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 17, height: 17)
                    }
                }
                .buttonStyle(.authTonal)

                Button {
                    error = nil
                    step = .email
                } label: {
                    Label("Continue with email", systemImage: "envelope")
                }
                .buttonStyle(.authTonal)
            }
            .disabled(isLoading)
        }
    }

    private var emailPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                error = nil
                step = .methods
            } label: {
                Text("← Other ways to sign in")
                    .font(.peatedInteractiveSmall)
                    .foregroundColor(.brandEmphasis)
                    .frame(minHeight: DesignSystem.ControlHeight.standard)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Other ways to sign in")
            .padding(.bottom, DesignSystem.Spacing.small)

            panelHeader(title: "Sign in with email", description: "Use the email and password for your account.")

            errorNotice

            VStack(spacing: DesignSystem.Spacing.medium) {
                TextInput(
                    label: "Email",
                    placeholder: "you@example.com",
                    text: $email,
                    keyboard: .emailAddress,
                    contentType: .username,
                    submitLabel: .next,
                    autocorrection: false,
                    capitalization: .never,
                    isFocused: $isEmailFocused
                )

                PasswordInput(
                    label: "Password",
                    placeholder: "Password",
                    text: $password,
                    submitLabel: .go,
                    onSubmit: { handleLogin() }
                )
            }
            .padding(.bottom, DesignSystem.Spacing.xLarge)

            // Stays enabled so it keeps full contrast. Missing fields get an inline error instead.
            Button("Sign in", action: handleLogin)
                .buttonStyle(.authAccent)
        }
        .onAppear { isEmailFocused = true }
    }

    private func panelHeader(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
            Text(title)
                .font(.peatedPageTitleCompact)
                .tracking(DesignSystem.Tracking.pageTitleCompact)
                .fontWeight(.bold)
                .foregroundColor(.text)
                .accessibilityAddTraits(.isHeader)

            Text(description)
                .font(.peatedBody)
                .foregroundColor(.textSecondary)
        }
        .padding(.bottom, DesignSystem.Spacing.xLarge)
    }

    @ViewBuilder
    private var errorNotice: some View {
        if let error {
            Text(error)
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
        }
    }

    // MARK: - Account Links

    private var accountLinks: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(Color.border)
                .frame(height: DesignSystem.Border.thin)
                .padding(.vertical, 26)

            // One layout that changes axis keeps each link the same element as the text size changes.
            let layout = stacksAccountLinks
                ? AnyLayout(VStackLayout(alignment: .leading, spacing: 0))
                : AnyLayout(HStackLayout(spacing: DesignSystem.Spacing.small))
            layout {
                accountLinkItems(separated: !stacksAccountLinks)
            }
            .font(.peatedMetadata)
            .foregroundColor(.textMuted)
        }
    }

    /// The footer fits on one line at the default text sizes.
    private var stacksAccountLinks: Bool {
        dynamicTypeSize > .large
    }

    @ViewBuilder
    private func accountLinkItems(separated: Bool) -> some View {
        HStack(spacing: DesignSystem.Spacing.small) {
            Text("No account yet?")

            NavigationLink(
                destination: SignUpView { user in
                    onLoginSuccess(user)
                }
            ) {
                accountLinkLabel("Create one")
            }
            .accessibilityIdentifier(AccessibilityID.Auth.signUpLink)
        }

        if separated {
            Text("·")
                .accessibilityHidden(true)
        }

        Link(destination: PeatedWebURL.recoverAccount) {
            accountLinkLabel("Recover your account")
        }
    }

    private func accountLinkLabel(_ title: String) -> some View {
        Text(title)
            .font(.peatedInteractiveSmall)
            .foregroundColor(.brandEmphasis)
            // Keep the bare text link at the 44-point minimum hit target.
            .frame(minHeight: DesignSystem.ControlHeight.standard)
            .contentShape(Rectangle())
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

    private func handleLogin() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            error = "Enter your email and password."
            return
        }

        Task {
            isLoading = true
            error = nil
            do {
                let user = try await authManager.login(email: trimmedEmail, password: password)
                await MainActor.run {
                    isLoading = false
                    onLoginSuccess(user)
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func handlePasskeySignIn() {
        Task {
            isLoading = true
            error = nil
            do {
                let user = try await authManager.loginWithPasskey { challenge in
                    try await passkeyRequester.requestPasskey(for: challenge)
                }
                isLoading = false
                if let user {
                    onLoginSuccess(user)
                }
            } catch {
                self.error = error.localizedDescription
                isLoading = false
            }
        }
    }

    private func handleAppleSignIn(_ credential: AppleSignInCredential) {
        Task {
            isLoading = true
            error = nil

            do {
                let user = try await authManager.loginWithApple(
                    identityToken: credential.identityToken,
                    fullName: credential.fullName
                )
                await MainActor.run {
                    isLoading = false
                    onLoginSuccess(user)
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func handleGoogleSignIn() {
        Task {
            isLoading = true
            error = nil

            do {
                let user = try await authManager.loginWithGoogle()
                await MainActor.run {
                    isLoading = false
                    onLoginSuccess(user)
                }
            } catch {
                await MainActor.run {
                    // Ignore user-cancelled sign-in; no alert needed
                    if !isGoogleCancel(error) {
                        self.error = error.localizedDescription
                    }
                    isLoading = false
                }
            }
        }
    }

    private func isGoogleCancel(_ error: Error) -> Bool {
        let ns = error as NSError
        let message = error.localizedDescription.lowercased()
        // GoogleSignIn SDK cancellation (domain often contains com.google, code -5)
        if ns.domain.contains("com.google"), ns.code == -5 || message.contains("cancel") {
            return true
        }
        // ASWebAuthenticationSession user cancel
        if ns.domain.contains("AuthenticationServices") || ns.domain.contains("WebAuthenticationSession"),
           ns.code == 1 || ns.code == 1001 {
            return true
        }
        // Fallback: message contains cancel
        if message.contains("cancel") {
            return true
        }
        return false
    }
}
