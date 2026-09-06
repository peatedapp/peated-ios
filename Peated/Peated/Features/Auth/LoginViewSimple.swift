import GoogleSignIn
import PeatedCore
import SwiftUI

/// Simple login view that directly updates app state
struct LoginViewSimple: View {
    let onLoginSuccess: (User) -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var error: String?

    let authManager = AuthenticationManager.shared

    var body: some View {
        ZStack {
            Color.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Logo and header
                    headerSection
                        .padding(.top, 60)

                    // Google Sign In
                    googleSignInButton
                        .padding(.horizontal)

                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color.border)
                            .frame(height: 1)

                        Text("OR")
                            .font(.peatedCaption)
                            .foregroundColor(.textMuted)
                            .padding(.horizontal, 16)

                        Rectangle()
                            .fill(Color.border)
                            .frame(height: 1)
                    }
                    .padding(.horizontal)

                    loginForm
                        .padding(.horizontal)

                    // Login button
                    loginButton
                        .padding(.horizontal)
                        .padding(.top, 8)

                    // Sign up link
                    signUpLink
                        .padding(.top, 16)

                    Spacer(minLength: 40)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .navigationBarHidden(true)
        .alert("Sign In Failed", isPresented: Binding(get: { error != nil }, set: {
            if !$0 {
                error = nil
            }
        })) { Button("OK") { error = nil } } message: { Text(error ?? "An error occurred") }
        .overlay(loadingOverlay)
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 24) {
            PeatedLogo(height: 60)
                .accessibilityLabel("Peated logo")

            VStack(spacing: 8) {
                Text("Welcome back")
                    .font(.peatedTitle2)
                    .fontWeight(.bold)
                    .foregroundColor(.text)

                Text("Track and share your whisky journey")
                    .font(.peatedBody)
                    .foregroundColor(.textSecondary)
            }
        }
    }

    // MARK: - Google Sign In

    private var googleSignInButton: some View {
        Button(action: handleGoogleSignIn) {
            HStack(spacing: 12) {
                Image(systemName: "g.circle.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.onBrand)
                Text("Continue with Google")
                    .font(.peatedBody)
                    .fontWeight(.semibold)
                    .foregroundColor(.onBrand)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.brand)
            .cornerRadius(12)
        }
        .disabled(isLoading)
    }

    // MARK: - Login Form

    private var loginForm: some View {
        VStack(spacing: 16) {
            TextInput(
                label: "Email",
                placeholder: "Email",
                text: $email,
                keyboard: .emailAddress,
                submitLabel: .next,
                autocorrection: false,
                capitalization: .never
            )

            PasswordInput(
                label: "Password",
                placeholder: "Password",
                text: $password,
                submitLabel: .go,
                onSubmit: { handleLogin() }
            )
        }
    }

    // MARK: - Login Button

    private var loginButton: some View {
        Button(action: handleLogin) {
            Text("Sign In")
                .font(.peatedBody)
                .fontWeight(.semibold)
                .foregroundColor(.onBrand)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.brand)
                .cornerRadius(12)
        }
        .disabled(email.isEmpty || password.isEmpty || isLoading)
    }

    // MARK: - Sign Up Link

    private var signUpLink: some View {
        HStack {
            Text("Don't have an account?")
                .font(.peatedBody)
                .foregroundColor(.textSecondary)

            NavigationLink(
                destination: SignUpView { user in
                    onLoginSuccess(user)
                }
            ) {
                Text("Sign up")
                    .font(.peatedBody)
                    .fontWeight(.medium)
                    .foregroundColor(.brand)
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

    private func handleLogin() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !password.isEmpty else { return }

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
