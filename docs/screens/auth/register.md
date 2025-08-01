# Registration Screen

## Overview

The registration screen allows new users to create an account via email/password or Google OAuth. It includes username selection and email verification flow.

## Visual Layout

```
┌─────────────────────────────────────────┐
│         ← Back                          │
├─────────────────────────────────────────┤
│                                         │
│              [Peated Logo]              │
│                                         │
│         Create your account             │
│      Join the whisky community          │
│                                         │
│    ┌─────────────────────────────┐     │
│    │   🔷 Sign up with Google    │     │
│    └─────────────────────────────┘     │
│                                         │
│            ──── OR ────                 │
│                                         │
│    ┌─────────────────────────────┐     │
│    │ Email                        │     │
│    └─────────────────────────────┘     │
│                                         │
│    ┌─────────────────────────────┐     │
│    │ Username                     │     │
│    └─────────────────────────────┘     │
│    ✓ Username available                 │
│                                         │
│    ┌─────────────────────────────┐     │
│    │ Password                  👁 │     │
│    └─────────────────────────────┘     │
│    • At least 8 characters             │
│                                         │
│    ┌─────────────────────────────┐     │
│    │ Confirm Password          👁 │     │
│    └─────────────────────────────┘     │
│                                         │
│    ☐ I agree to the Terms of Service   │
│      and Privacy Policy                 │
│                                         │
│    ┌─────────────────────────────┐     │
│    │       Create Account        │     │
│    └─────────────────────────────┘     │
│                                         │
│    Already have an account? Sign in     │
│                                         │
└─────────────────────────────────────────┘
```

## Implementation

```swift
import SwiftUI

struct RegistrationScreen: View {
    // MARK: - Model
    @State private var model = RegistrationModel()
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    @State private var email = ""
    @State private var username = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var agreedToTerms = false
    @State private var isPasswordVisible = false
    @State private var isConfirmPasswordVisible = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, username, password, confirmPassword
    }
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Logo and header
                headerSection
                    .padding(.top, 40)
                
                // Google Sign Up
                googleSignUpButton
                    .padding(.horizontal)
                
                // Divider
                dividerSection
                    .padding(.horizontal)
                
                // Registration form
                VStack(spacing: 16) {
                    emailField
                    usernameField
                    passwordField
                    confirmPasswordField
                    termsCheckbox
                }
                .padding(.horizontal)
                
                // Create Account button
                createAccountButton
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Sign in link
                signInLink
                    .padding(.top, 16)
                
                Spacer(minLength: 40)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Back") {
                    dismiss()
                }
            }
        }
        .alert("Verify Your Email", isPresented: $model.showVerificationAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("We've sent a verification email to \(email). Please check your inbox and verify your email to continue.")
        }
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
                .frame(width: 100, height: 100)
            
            VStack(spacing: 8) {
                Text("Create your account")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Join the whisky community")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
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
                .onChange(of: email) { _ in
                    model.validateEmail(email)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .overlay(fieldBorder(for: .email))
            
            if let error = model.emailError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
    
    // MARK: - Username Field
    @ViewBuilder
    private var usernameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Username")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                TextField("johndoe", text: $username)
                    .textFieldStyle(.plain)
                    .autocapitalization(.none)
                    .focused($focusedField, equals: .username)
                    .onChange(of: username) { newValue in
                        model.checkUsernameAvailability(newValue)
                    }
                
                if model.isCheckingUsername {
                    ProgressView()
                        .scaleEffect(0.8)
                } else if let available = model.isUsernameAvailable {
                    Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(available ? .green : .red)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .overlay(fieldBorder(for: .username))
            
            if let message = model.usernameMessage {
                Text(message)
                    .font(.caption)
                    .foregroundColor(model.isUsernameAvailable == true ? .green : .red)
            }
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
            .overlay(fieldBorder(for: .password))
            .onChange(of: password) { _ in
                model.validatePassword(password)
            }
            
            // Password requirements
            VStack(alignment: .leading, spacing: 4) {
                PasswordRequirement(
                    text: "At least 8 characters",
                    isMet: password.count >= 8
                )
                PasswordRequirement(
                    text: "Contains uppercase letter",
                    isMet: password.rangeOfCharacter(from: .uppercaseLetters) != nil
                )
                PasswordRequirement(
                    text: "Contains number",
                    isMet: password.rangeOfCharacter(from: .decimalDigits) != nil
                )
            }
        }
    }
    
    // MARK: - Confirm Password Field
    @ViewBuilder
    private var confirmPasswordField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Confirm Password")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                if isConfirmPasswordVisible {
                    TextField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle(.plain)
                        .focused($focusedField, equals: .confirmPassword)
                } else {
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle(.plain)
                        .focused($focusedField, equals: .confirmPassword)
                }
                
                Button(action: { isConfirmPasswordVisible.toggle() }) {
                    Image(systemName: isConfirmPasswordVisible ? "eye.slash" : "eye")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .overlay(fieldBorder(for: .confirmPassword))
            
            if !confirmPassword.isEmpty && confirmPassword != password {
                Text("Passwords don't match")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
    
    // MARK: - Terms Checkbox
    @ViewBuilder
    private var termsCheckbox: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: { agreedToTerms.toggle() }) {
                Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                    .foregroundColor(agreedToTerms ? .accentColor : .secondary)
                    .font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("I agree to the ")
                    .font(.caption) +
                Text("Terms of Service")
                    .font(.caption)
                    .foregroundColor(.accentColor)
                    .underline() +
                Text(" and ")
                    .font(.caption) +
                Text("Privacy Policy")
                    .font(.caption)
                    .foregroundColor(.accentColor)
                    .underline()
            }
            .multilineTextAlignment(.leading)
            .onTapGesture {
                agreedToTerms.toggle()
            }
            
            Spacer()
        }
    }
    
    // MARK: - Create Account Button
    @ViewBuilder
    private var createAccountButton: some View {
        Button(action: handleCreateAccount) {
            Text("Create Account")
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.accentColor)
                .cornerRadius(25)
        }
        .disabled(!isFormValid)
        .opacity(isFormValid ? 1.0 : 0.6)
    }
    
    // MARK: - Helper Views
    private func fieldBorder(for field: Field) -> some View {
        RoundedRectangle(cornerRadius: 12)
            .stroke(
                focusedField == field ? Color.accentColor : Color.clear,
                lineWidth: 2
            )
    }
    
    private var isFormValid: Bool {
        !email.isEmpty &&
        model.emailError == nil &&
        !username.isEmpty &&
        model.isUsernameAvailable == true &&
        password.count >= 8 &&
        password == confirmPassword &&
        agreedToTerms
    }
    
    // MARK: - Actions
    private func handleCreateAccount() {
        Task {
            await model.createAccount(
                email: email,
                username: username,
                password: password
            )
        }
    }
}

// MARK: - Password Requirement View
struct PasswordRequirement: View {
    let text: String
    let isMet: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .font(.caption)
                .foregroundColor(isMet ? .green : .secondary)
            
            Text(text)
                .font(.caption)
                .foregroundColor(isMet ? .primary : .secondary)
            
            Spacer()
        }
    }
}

// MARK: - Model
@Observable
class RegistrationModel {
    var isLoading = false
    var showError = false
    var errorMessage = ""
    var showVerificationAlert = false
    
    // Validation states
    var emailError: String?
    var isCheckingUsername = false
    var isUsernameAvailable: Bool?
    var usernameMessage: String?
    
    private let authManager = AuthManager.shared
    private var usernameCheckTask: Task<Void, Never>?
    
    func validateEmail(_ email: String) {
        if email.isEmpty {
            emailError = nil
            return
        }
        
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        
        if !emailPredicate.evaluate(with: email) {
            emailError = "Invalid email format"
        } else {
            emailError = nil
        }
    }
    
    func checkUsernameAvailability(_ username: String) {
        // Cancel previous check
        usernameCheckTask?.cancel()
        
        guard !username.isEmpty else {
            isUsernameAvailable = nil
            usernameMessage = nil
            return
        }
        
        // Validate format first
        if username.count < 3 {
            isUsernameAvailable = false
            usernameMessage = "Username must be at least 3 characters"
            return
        }
        
        if !username.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "_" }) {
            isUsernameAvailable = false
            usernameMessage = "Username can only contain letters, numbers, and underscores"
            return
        }
        
        // Check availability
        isCheckingUsername = true
        usernameCheckTask = Task {
            do {
                // Simulate API delay
                try await Task.sleep(nanoseconds: 500_000_000)
                
                let available = try await UsersAPI.checkUsername(username)
                
                if !Task.isCancelled {
                    isUsernameAvailable = available
                    usernameMessage = available ? "Username available" : "Username already taken"
                    isCheckingUsername = false
                }
            } catch {
                if !Task.isCancelled {
                    isUsernameAvailable = nil
                    usernameMessage = nil
                    isCheckingUsername = false
                }
            }
        }
    }
    
    func validatePassword(_ password: String) -> Bool {
        password.count >= 8 &&
        password.rangeOfCharacter(from: .uppercaseLetters) != nil &&
        password.rangeOfCharacter(from: .decimalDigits) != nil
    }
    
    func createAccount(email: String, username: String, password: String) async {
        isLoading = true
        showError = false
        
        do {
            try await authManager.register(
                email: email,
                username: username,
                password: password
            )
            showVerificationAlert = true
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isLoading = false
    }
}
```

## Navigation

### Entry Points
- "Sign up" link from login screen
- Deep link for new users
- App launch (first time)

### Exit Points
- Successful registration → Email verification notice → Login
- "Sign in" link → Login screen
- Back button → Previous screen

## Data Requirements

### API Endpoints
- `POST /auth/register` - Create new account
- `GET /users/check-username/{username}` - Check username availability
- `POST /auth/verify-email` - Verify email address

### Validation Rules
- **Email**: Valid format, not already registered
- **Username**: 3-20 characters, alphanumeric + underscore, unique
- **Password**: Minimum 8 characters, uppercase, number
- **Terms**: Must be accepted

## Error Handling

### Field Validation
- Real-time email format validation
- Async username availability check
- Password strength requirements
- Matching password confirmation

### Registration Errors
- Email already exists
- Username taken
- Weak password
- Network failure
- Server errors

## Security Considerations

- Password requirements enforced
- Email verification required
- Rate limiting on registration
- Username enumeration protection
- HTTPS only

## Accessibility

- Form fields properly labeled
- Error messages announced
- Password visibility toggle
- Keyboard navigation support
- VoiceOver optimized

## Testing Scenarios

1. Valid registration flow
2. Duplicate email/username
3. Weak password rejection
4. Network interruption
5. Terms not accepted
6. Email verification flow