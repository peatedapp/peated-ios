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
    @State private var showTerms = false

    private let authManager = AuthenticationManager.shared

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.background, Color.surface]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                        .padding(.top, 60)

                    googleSignUpButton
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
        .sheet(isPresented: $showTerms) {
            if let url = URL(string: "https://peated.com/terms") {
                SafariView(url: url)
                    .ignoresSafeArea(edges: .bottom)
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(spacing: 8) {
            PeatedLogo(height: 60)
            Text("Join Peated")
                .font(.peatedTitle2)
                .fontWeight(.bold)
                .foregroundColor(.text)
            Text("Track and share your whisky journey")
                .font(.peatedBody)
                .foregroundColor(.textSecondary)
        }
    }

    private var divider: some View {
        HStack {
            Rectangle().fill(Color.border).frame(height: 1)
            Text("OR").font(.peatedCaption).foregroundColor(.textMuted).padding(.horizontal, 16)
            Rectangle().fill(Color.border).frame(height: 1)
        }
    }

    private var formFields: some View {
        VStack(spacing: 16) {
            TextInput(
                label: "Username",
                placeholder: "yourname",
                text: $username,
                keyboard: .asciiCapable,
                submitLabel: .next,
                autocorrection: false,
                capitalization: .never
            )

            TextInput(
                label: "Email",
                placeholder: "you@example.com",
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
                submitLabel: .done,
                onSubmit: { handleEmailSignUp() }
            )
        }
    }

    private var termsRow: some View {
        HStack(alignment: .center, spacing: 10) {
            Toggle(isOn: $acceptedTerms) { EmptyView() }
                .toggleStyle(.switch)
                .tint(.brand)
                .labelsHidden()

            HStack(spacing: 4) {
                Text("I agree to the")
                    .foregroundColor(.textSecondary)
                Button(action: { showTerms = true }) {
                    Text("Terms of Service")
                        .foregroundColor(.brand)
                        .underline()
                }
                .buttonStyle(.plain)
            }
        }
        .font(.peatedCaption)
    }

    private var signUpButton: some View {
        Button(action: handleEmailSignUp) {
            Text("Create Account")
                .font(.peatedBody)
                .fontWeight(.semibold)
                .foregroundColor(.onBrand)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isPrimaryEnabled ? Color.brand : Color.brand.opacity(0.5))
                .cornerRadius(12)
        }
        .disabled(!isPrimaryEnabled || isLoading)
    }

    private var isPrimaryEnabled: Bool {
        !username.isEmpty && !email.isEmpty && !password.isEmpty && acceptedTerms && !isLoading
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
                        .font(.peatedBody)
                        .fontWeight(.semibold)
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
