# Login Screen

## Overview

The login screen is the primary entry point for returning users. It supports both email/password authentication and Google OAuth sign-in, matching the authentication methods provided by the Peated API.

## Visual Layout

```
┌─────────────────────────────────────────┐
│                                         │
│              [Peated Logo]              │
│                                         │
│         Welcome back to Peated          │
│      Track and share your journey       │
│                                         │
│    ┌─────────────────────────────┐     │
│    │   🔷 Sign in with Google    │     │
│    └─────────────────────────────┘     │
│                                         │
│            ──── OR ────                 │
│                                         │
│    ┌─────────────────────────────┐     │
│    │ Email                        │     │
│    └─────────────────────────────┘     │
│                                         │
│    ┌─────────────────────────────┐     │
│    │ Password                  👁 │     │
│    └─────────────────────────────┘     │
│                                         │
│    Forgot password?                     │
│                                         │
│    ┌─────────────────────────────┐     │
│    │         Sign In             │     │
│    └─────────────────────────────┘     │
│                                         │
│    Don't have an account? Sign up       │
│                                         │
└─────────────────────────────────────────┘
```

## Implementation

```swift
import SwiftUI
import AuthenticationServices

struct LoginScreen: View {
    // MARK: - Model
    @State private var model = LoginModel()
    @EnvironmentObject var authManager: AuthManager
    
    // MARK: - State
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }
    
    // MARK: - Body
    var body: some View {
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
                        .fill(Color(.separator))
                        .frame(height: 1)
                    
                    Text("OR")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                    
                    Rectangle()
                        .fill(Color(.separator))
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
        .navigationBarHidden(true)
        .alert("Error", isPresented: $model.showError) {
            Button("OK") { }
        } message: {
            Text(model.errorMessage)
        }
        .overlay(loadingOverlay)
    }
    
    // MARK: - Header Section
    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image("PeatedLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .accessibilityLabel("Peated logo")
            
            VStack(spacing: 8) {
                Text("Welcome back to Peated")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Track and share your journey")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // MARK: - Google Sign In
    @ViewBuilder
    private var googleSignInButton: some View {
        SignInWithAppleButton(.signIn) { request in
            // We'll use this as a template but implement Google
        } onCompletion: { result in
            // Handle result
        }
        .signInWithAppleButtonStyle(.black)
        .frame(height: 50)
        .cornerRadius(25)
        .overlay(
            // Custom Google button overlay
            Button(action: handleGoogleSignIn) {
                HStack {
                    Image("GoogleLogo")
                        .resizable()
                        .frame(width: 20, height: 20)
                    
                    Text("Sign in with Google")
                        .font(.body)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(red: 0.26, green: 0.52, blue: 0.96))
            .cornerRadius(25)
        )
    }
    
    // MARK: - Email Field
    @ViewBuilder
    private var emailField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Email")
                .font(.caption)
                .foregroundColor(.secondary)
            
            TextField("you@example.com", text: $email)
                .textFieldStyle(.plain)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .focused($focusedField, equals: .email)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            focusedField == .email ? Color.accentColor : Color.clear,
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
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                if isPasswordVisible {
                    TextField("Password", text: $password)
                        .textFieldStyle(.plain)
                        .focused($focusedField, equals: .password)
                } else {
                    SecureField("Password", text: $password)
                        .textFieldStyle(.plain)
                        .focused($focusedField, equals: .password)
                }
                
                Button(action: { isPasswordVisible.toggle() }) {
                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        focusedField == .password ? Color.accentColor : Color.clear,
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
                // Handle forgot password
            }
            .font(.caption)
            .foregroundColor(.accentColor)
        }
    }
    
    // MARK: - Sign In Button
    @ViewBuilder
    private var signInButton: some View {
        Button(action: handleEmailSignIn) {
            Text("Sign In")
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.accentColor)
                .cornerRadius(25)
        }
        .disabled(email.isEmpty || password.isEmpty || model.isLoading)
    }
    
    // MARK: - Sign Up Link
    @ViewBuilder
    private var signUpLink: some View {
        HStack {
            Text("Don't have an account?")
                .font(.body)
                .foregroundColor(.secondary)
            
            NavigationLink("Sign up") {
                RegistrationScreen()
            }
            .font(.body)
            .fontWeight(.medium)
            .foregroundColor(.accentColor)
        }
    }
    
    // MARK: - Loading Overlay
    @ViewBuilder
    private var loadingOverlay: some View {
        if model.isLoading {
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
            await model.signIn(email: email, password: password)
        }
    }
    
    private func handleGoogleSignIn() {
        Task {
            await model.signInWithGoogle()
        }
    }
}

// MARK: - Model
@Observable
class LoginModel {
    var isLoading = false
    var showError = false
    var errorMessage = ""
    
    private let authManager = AuthManager.shared
    
    func signIn(email: String, password: String) async {
        isLoading = true
        showError = false
        
        do {
            try await authManager.login(email: email, password: password)
            // Navigation handled by AuthManager
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    func signInWithGoogle() async {
        isLoading = true
        showError = false
        
        do {
            // 1. Present Google Sign-In
            let authCode = try await presentGoogleSignIn()
            
            // 2. Exchange code with backend
            try await authManager.loginWithGoogle(authCode: authCode)
            // Navigation handled by AuthManager
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
    
    private func presentGoogleSignIn() async throws -> String {
        // Google Sign-In SDK implementation
        // Returns authorization code
        throw AuthError.notImplemented
    }
}
```

## Navigation

### Entry Points
- App launch (not authenticated)
- Sign out from settings
- Session expiration
- Deep link to protected content

### Exit Points
- Successful login → Main tab view
- Sign up link → Registration screen
- Forgot password → Password reset flow

## Data Requirements

### API Endpoints
- `POST /auth/login` - Email/password authentication
- `POST /auth/google` - Google OAuth authentication

### Request Formats
```swift
// Email/Password
struct EmailLoginRequest: Codable {
    let email: String
    let password: String
}

// Google OAuth
struct GoogleLoginRequest: Codable {
    let code: String
}
```

### Response Format
```swift
struct AuthResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let user: User
}
```

## State Management

### Local State
- Email input
- Password input
- Password visibility toggle
- Loading state
- Error messages
- Focused field

### Validation
- Email format validation
- Non-empty password
- Show inline errors
- Disable submit when invalid

## Error Handling

### Network Errors
- No connection: "Unable to connect. Please check your internet connection."
- Timeout: "Request timed out. Please try again."
- Server error: "Something went wrong. Please try again later."

### Authentication Errors
- Invalid credentials: "Invalid email or password."
- Account locked: "Your account has been locked. Please contact support."
- Email not verified: "Please verify your email address."

### Google Sign-In Errors
- Cancelled: No error shown
- Failed: "Google sign-in failed. Please try again."
- Invalid code: "Authentication failed. Please try again."

## Accessibility

### VoiceOver
- Logo: "Peated logo"
- Fields: "Email, text field" / "Password, secure text field"
- Buttons: "Sign in with Google, button" / "Sign in, button"
- Links: "Forgot password, button" / "Sign up, link"

### Keyboard Navigation
- Tab through all interactive elements
- Return key advances to next field
- Submit on return from password field

## Security Considerations

### Password Handling
- Never log passwords
- Clear on navigation away
- Use SecureField for input
- Support password managers

### Token Storage
- Store in iOS Keychain
- Never in UserDefaults
- Clear on sign out
- Refresh token rotation

## Testing Scenarios

### Success Cases
1. Valid email/password login
2. Google sign-in flow
3. Remember me functionality
4. Auto-fill credentials

### Error Cases
1. Invalid email format
2. Wrong password
3. Network failure
4. Google sign-in cancellation

### Edge Cases
1. Rapid submit attempts
2. Very long email/password
3. Special characters
4. Switching auth methods