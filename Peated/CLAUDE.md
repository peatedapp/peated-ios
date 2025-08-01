## General

- Peated is a native iOS app for whisky enthusiasts to track, rate, and discover whiskies
- The app is inspired by Untappd's social features, creating a community around whisky appreciation
- Built using SwiftUI with UIKit integration where necessary via UIViewRepresentable
- Target iOS 17.0+ to leverage the latest iOS features and APIs
- Use Swift 6.0 with strict concurrency enabled
- Follow Apple Human Interface Guidelines for iOS app design
- Use SF Symbols for iconography throughout the app

For comprehensive documentation see:
- @docs/architecture/overview.md - System architecture
- @docs/architecture/tech-stack.md - Technology choices
- @docs/implementation/phases.md - Implementation roadmap
- @docs/references/modern-swift.md - Swift best practices

## Architecture

- Follow Model-View (MV) pattern using @Observable (iOS 17+)
- All business logic and API interactions are in PeatedCore package
- Features are organized into separate modules under Features/
- Common UI components and utilities in Common/
- Models serve as both data and view state using @Observable
- Direct state manipulation without actions/reducers

### MV Pattern Example:
```swift
// Model (in PeatedCore)
@Observable
public class LoginModel {
    public var email = ""
    public var password = ""
    public var isLoading = false
    public var error: Error?
    
    private let authManager = AuthenticationManager.shared
    
    public func login() async {
        isLoading = true
        error = nil
        do {
            _ = try await authManager.login(email: email, password: password)
        } catch {
            self.error = error
        }
        isLoading = false
    }
}

// View (in Peated app)
struct LoginView: View {
    @State private var model = LoginModel()
    
    var body: some View {
        Form {
            TextField("Email", text: $model.email)
            SecureField("Password", text: $model.password)
            Button("Login") {
                Task { await model.login() }
            }
            .disabled(model.isLoading)
        }
    }
}
```

## Code Style

- Use 2 spaces for indentation (following Context's style)
- Follow Swift API Design Guidelines
- Run `swift format` for code formatting
- Minimize comments in function bodies

## Project Structure

- **App/**: Main app entry point and root feature
- **Features/**: Feature-specific views and models
- **Common/**: Shared components, extensions, and utilities
- **Resources/**: Assets, Info.plist, and other resources
- **Dependencies/**: App-specific dependency configurations

## Testing

- Use Swift Testing framework for unit tests
- Use XCUITest for UI automation tests
- Test models and view logic thoroughly
- UI tests should cover critical user flows

## Build and Run

- Use Xcode 16.0+ for development
- The app depends on PeatedCore Swift Package
- Run the app using standard Xcode commands
- Use the xcode-builder agent for CI builds

## Core Features

- **Whisky Check-ins**: Rate and review whiskies with photos and tasting notes
- **Social Feed**: Follow friends and discover what they're drinking
- **Discovery**: Search extensive whisky database
- **Personal Library**: Track whisky journey with statistics
- **Offline Support**: Full functionality without internet connection

## Key Dependencies (via PeatedCore)

- SQLite.swift (0.14.0+) - Type-safe SQLite wrapper for local storage
- OpenAPI Runtime (1.0.0+) - Runtime support for generated API client
- OpenAPI URLSession (1.0.0+) - HTTP transport for API client
- Google Sign-In for iOS (8.0.0+) - OAuth authentication
- KeychainAccess (4.2.0+) - Secure credential storage

Note: We use manual OpenAPI generation, not the build plugin. See @../docs/openapi-workflow.md

## Performance

- Lazy loading for images in lists
- Implement view recycling for large datasets
- Use background queues for heavy operations
- Target 60fps scrolling performance
- Implement skeleton screens during data loads