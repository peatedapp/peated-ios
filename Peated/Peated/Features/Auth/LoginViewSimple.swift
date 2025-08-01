import SwiftUI
import PeatedCore

// Simple login view that directly updates app state
struct LoginViewSimple: View {
  let onLoginSuccess: (User) -> Void
  
  @State private var email = ""
  @State private var password = ""
  @State private var isPasswordVisible = false
  @State private var isLoading = false
  @State private var error: String?
  @FocusState private var focusedField: Field?
  
  let authManager = AuthenticationManager.shared
  
  enum Field {
    case email, password
  }
  
  var body: some View {
    ZStack {
      // Background gradient
      LinearGradient(
        gradient: Gradient(colors: [Color.peatedBackground, Color.peatedSurface]),
        startPoint: .top,
        endPoint: .bottom
      )
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
              .fill(Color.peatedBorder)
              .frame(height: 1)
            
            Text("OR")
              .font(.peatedCaption)
              .foregroundColor(.peatedTextMuted)
              .padding(.horizontal, 16)
            
            Rectangle()
              .fill(Color.peatedBorder)
              .frame(height: 1)
          }
          .padding(.horizontal)
          
          // Email/Password form
          VStack(spacing: 16) {
            emailField
            passwordField
            forgotPasswordLink
          }
          .padding(.horizontal)
          
          // Sign In button
          signInButton
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
    .alert("Sign In Failed", isPresented: .constant(error != nil)) {
      Button("OK") { error = nil }
    } message: {
      Text(error ?? "An error occurred")
    }
    .overlay(loadingOverlay)
  }
  
  // MARK: - Header Section
  @ViewBuilder
  private var headerSection: some View {
    VStack(spacing: 24) {
      PeatedLogo(height: 60)
        .accessibilityLabel("Peated logo")
      
      VStack(spacing: 8) {
        Text("Welcome back")
          .font(.peatedTitle2)
          .fontWeight(.bold)
          .foregroundColor(.peatedTextPrimary)
        
        Text("Track and share your whisky journey")
          .font(.peatedBody)
          .foregroundColor(.peatedTextSecondary)
      }
    }
  }
  
  // MARK: - Google Sign In
  @ViewBuilder
  private var googleSignInButton: some View {
    Button(action: handleGoogleSignIn) {
      HStack(spacing: 12) {
        Text("G")
          .font(.system(size: 20, weight: .bold, design: .serif))
          .foregroundColor(.peatedBackground)
        
        Text("Sign in with Google")
          .font(.peatedBody)
          .fontWeight(.semibold)
          .foregroundColor(.peatedBackground)
      }
      .frame(maxWidth: .infinity)
      .padding(.vertical, 16)
      .background(Color.peatedGold)
      .cornerRadius(12)
    }
    .disabled(isLoading)
  }
  
  // MARK: - Email Field
  @ViewBuilder
  private var emailField: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Email")
        .font(.peatedCaption)
        .foregroundColor(.peatedTextSecondary)
      
      PeatedTextField(
        placeholder: "you@example.com",
        text: $email
      )
      .keyboardType(.emailAddress)
      .textContentType(.emailAddress)
      .autocapitalization(.none)
      .disableAutocorrection(true)
      .focused($focusedField, equals: .email)
      .padding()
      .background(Color.peatedSurfaceLight)
      .cornerRadius(12)
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(
            focusedField == .email ? Color.peatedGold : Color.clear,
            lineWidth: 2
          )
      )
    }
  }
  
  // MARK: - Password Field
  @ViewBuilder
  private var passwordField: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Password")
        .font(.peatedCaption)
        .foregroundColor(.peatedTextSecondary)
      
      HStack {
        PeatedTextField(
          placeholder: "Password",
          text: $password,
          isSecure: !isPasswordVisible
        )
        .focused($focusedField, equals: .password)
        
        Button {
          isPasswordVisible.toggle()
        } label: {
          Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
            .foregroundColor(.peatedTextSecondary)
        }
      }
      .padding()
      .background(Color.peatedSurfaceLight)
      .cornerRadius(12)
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(
            focusedField == .password ? Color.peatedGold : Color.clear,
            lineWidth: 2
          )
      )
    }
    .textContentType(.password)
  }
  
  // MARK: - Forgot Password
  @ViewBuilder
  private var forgotPasswordLink: some View {
    HStack {
      Spacer()
      Button("Forgot password?") {
        // TODO: Handle forgot password
      }
      .font(.peatedCaption)
      .foregroundColor(.peatedGold)
    }
  }
  
  // MARK: - Sign In Button
  @ViewBuilder
  private var signInButton: some View {
    Button(action: handleEmailSignIn) {
      Text("Sign In")
        .font(.peatedBody)
        .fontWeight(.semibold)
        .foregroundColor(.peatedBackground)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.peatedGold)
        .cornerRadius(12)
    }
    .disabled(email.isEmpty || password.isEmpty || isLoading)
  }
  
  // MARK: - Sign Up Link
  @ViewBuilder
  private var signUpLink: some View {
    HStack {
      Text("Don't have an account?")
        .font(.peatedBody)
        .foregroundColor(.peatedTextSecondary)
      
      Button("Sign up") {
        // TODO: Navigate to registration
      }
      .font(.peatedBody)
      .fontWeight(.medium)
      .foregroundColor(.peatedGold)
    }
  }
  
  // MARK: - Loading Overlay
  @ViewBuilder
  private var loadingOverlay: some View {
    if isLoading {
      Color.black.opacity(0.4)
        .ignoresSafeArea()
        .overlay(
          ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .white))
            .scaleEffect(1.5)
        )
    }
  }
  
  // MARK: - Actions
  private func handleEmailSignIn() {
    Task {
      isLoading = true
      error = nil
      
      do {
        let user = try await authManager.login(email: email, password: password)
        await MainActor.run {
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
}