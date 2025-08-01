# Dependencies & Package Management

## Overview

This document details all external dependencies, their purposes, and integration guidelines for the Peated iOS app. We maintain a minimal dependency approach, preferring native iOS frameworks where possible.

## Package Management

### Swift Package Manager (SPM)

We use Swift Package Manager exclusively for dependency management:

```swift
// Package.swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PeatedIOS",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "PeatedIOS",
            targets: ["PeatedIOS"]
        )
    ],
    dependencies: [
        // Database
        .package(
            url: "https://github.com/stephencelis/SQLite.swift",
            from: "0.14.0"
        ),
        
        // OpenAPI Generator & Runtime
        .package(
            url: "https://github.com/apple/swift-openapi-generator",
            from: "1.0.0"
        ),
        .package(
            url: "https://github.com/apple/swift-openapi-runtime", 
            from: "1.0.0"
        ),
        .package(
            url: "https://github.com/apple/swift-openapi-urlsession",
            from: "1.0.0"
        ),
        
        // Authentication
        .package(
            url: "https://github.com/google/GoogleSignIn-iOS",
            from: "7.0.0"
        ),
        
        // Image Loading
        .package(
            url: "https://github.com/onevcat/Kingfisher",
            from: "7.0.0"
        ),
        
        // Network Monitoring
        .package(
            url: "https://github.com/ashleymills/Reachability.swift",
            from: "5.0.0"
        )
    ],
    targets: [
        .target(
            name: "PeatedIOS",
            dependencies: [
                .product(name: "SQLite", package: "SQLite.swift"),
                .product(name: "OpenAPIGenerator", package: "swift-openapi-generator"),
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession"),
                .product(name: "GoogleSignIn", package: "GoogleSignIn-iOS"),
                .product(name: "Kingfisher", package: "Kingfisher"),
                .product(name: "Reachability", package: "Reachability.swift")
            ]
        ),
        .testTarget(
            name: "PeatedIOSTests",
            dependencies: ["PeatedIOS"]
        )
    ]
)
```

## Core Dependencies

### SQLite.swift

**Purpose**: Type-safe SQLite wrapper for local data persistence

**Version**: 0.14.0+

**Features Used**:
- Query builder with Swift syntax
- Automatic migrations
- Type-safe column definitions
- Full-text search
- JSON support for arrays/objects

**Usage**:
```swift
import SQLite

class DatabaseManager {
    private let db: Connection
    
    // Table definitions
    private let bottles = Table("bottles")
    private let id = Expression<String>("id")
    private let name = Expression<String>("name")
    private let avgRating = Expression<Double>("avg_rating")
    
    init() throws {
        let path = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true
        ).first!
        
        db = try Connection("\(path)/peated.sqlite3")
        try createTables()
    }
    
    private func createTables() throws {
        try db.run(bottles.create(ifNotExists: true) { t in
            t.column(id, primaryKey: true)
            t.column(name)
            t.column(avgRating, defaultValue: 0.0)
        })
    }
    
    func searchBottles(query: String) throws -> [Bottle] {
        let results = try db.prepare(
            bottles
                .filter(name.like("%\(query)%"))
                .order(avgRating.desc)
                .limit(20)
        )
        
        return results.map { row in
            Bottle(
                id: row[id],
                name: row[name],
                avgRating: row[avgRating]
            )
        }
    }
}
```

**Why SQLite over SwiftData**:
- More control over query optimization
- Better support for complex offline sync
- Mature and battle-tested
- Smaller overhead for simple data models
- Direct SQL when needed for performance

### OpenAPI Swift Generator

**Purpose**: Generate type-safe API client from Peated's OpenAPI specification

**Version**: 1.0.0+

**Integration**:
```swift
// openapi-generator-config.yaml
generate:
  - types
  - client

accessModifier: internal
module: PeatedAPI

// Build phase script
swift run swift-openapi-generator generate \
  --config openapi-generator-config.yaml \
  --output-directory ./Sources/PeatedAPI \
  peated-api.yaml
```

**Usage**:
```swift
import OpenAPIRuntime
import OpenAPIURLSession

let client = Client(
    serverURL: try Servers.server1(),
    transport: URLSessionTransport()
)

let response = try await client.getTastings()
```

### Google Sign-In for iOS

**Purpose**: OAuth authentication with Google accounts

**Version**: 7.0.0+

**Configuration**:
```xml
<!-- Info.plist -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

**Usage**:
```swift
import GoogleSignIn

// Configure in AppDelegate
GIDSignIn.sharedInstance.configuration = GIDConfiguration(
    clientID: "YOUR_CLIENT_ID"
)

// Sign in
try await GIDSignIn.sharedInstance.signIn(
    withPresenting: viewController
)
```

### Kingfisher

**Purpose**: Asynchronous image downloading and caching

**Version**: 7.0.0+

**Features Used**:
- Memory/disk caching
- Progressive image loading
- Image processors
- Placeholder support

**Usage**:
```swift
import Kingfisher

struct BottleImage: View {
    let url: URL?
    
    var body: some View {
        KFImage(url)
            .placeholder {
                Image("BottlePlaceholder")
            }
            .setProcessor(
                DownsamplingImageProcessor(size: CGSize(width: 200, height: 200))
            )
            .fade(duration: 0.25)
            .cacheMemoryOnly()
    }
}
```

### Reachability.swift

**Purpose**: Network connectivity monitoring

**Version**: 5.0.0+

**Usage**:
```swift
import Reachability

class NetworkMonitor: ObservableObject {
    private let reachability = try! Reachability()
    @Published var isConnected = true
    
    init() {
        reachability.whenReachable = { _ in
            self.isConnected = true
        }
        reachability.whenUnreachable = { _ in
            self.isConnected = false
        }
        try? reachability.startNotifier()
    }
}
```

## Development Dependencies

### SwiftLint (Optional)

**Purpose**: Enforce Swift style and conventions

**Installation**:
```bash
brew install swiftlint
```

**Configuration** (.swiftlint.yml):
```yaml
disabled_rules:
  - trailing_whitespace
  - line_length

opt_in_rules:
  - empty_count
  - closure_spacing
  - collection_alignment

excluded:
  - Sources/PeatedAPI # Generated code
  - .build

line_length:
  warning: 120
  error: 200
```

### SwiftFormat (Optional)

**Purpose**: Automatic code formatting

**Installation**:
```bash
brew install swiftformat
```

**Configuration** (.swiftformat):
```
--indent 4
--indentcase false
--stripunusedargs always
--self insert
--header strip
```

## Native iOS Frameworks

### Swift Concurrency
- **Purpose**: Async/await, actors
- **Min iOS**: 15.0
- **Usage**: All async operations

### Combine
- **Purpose**: Reactive programming
- **Min iOS**: 13.0
- **Usage**: ViewModels, publishers

### PhotosUI
- **Purpose**: Photo picker
- **Min iOS**: 16.0
- **Usage**: Tasting photo selection

### CoreLocation
- **Purpose**: Location services
- **Min iOS**: 2.0
- **Usage**: Check-in locations

### UserNotifications
- **Purpose**: Push notifications
- **Min iOS**: 10.0
- **Usage**: Social notifications

## Dependency Guidelines

### Selection Criteria

1. **Necessity**: Can't be reasonably built in-house
2. **Maintenance**: Active development, Swift-first
3. **Size**: Minimal impact on app size
4. **Quality**: Well-tested, documented
5. **License**: Compatible (MIT, Apache, etc.)

### Evaluation Process

Before adding a dependency:

```markdown
## Dependency Evaluation: [Package Name]

**Need**: What problem does it solve?
**Alternatives**: Native solutions or other packages
**Size Impact**: Framework size
**Maintenance**: Last update, issue response time
**Breaking Changes**: Version history
**Decision**: Accept/Reject with reasoning
```

### Version Management

- **Major versions**: Careful evaluation
- **Minor versions**: Test in development
- **Patch versions**: Auto-update allowed
- **Lock file**: Package.resolved committed

## Security Considerations

### Dependency Scanning

Regular security audits:

```bash
# Check for known vulnerabilities
swift package audit

# Review dependency tree
swift package show-dependencies --format tree
```

### API Key Management

Never commit API keys:

```swift
// Config.swift (git-ignored)
enum Config {
    static let googleClientID = "YOUR_CLIENT_ID"
    static let apiKey = "YOUR_API_KEY"
}

// Or use Info.plist with .gitignore
let clientID = Bundle.main.object(
    forInfoDictionaryKey: "GOOGLE_CLIENT_ID"
) as? String
```

## Troubleshooting

### Common Issues

1. **Package Resolution Failures**
   ```bash
   swift package resolve
   swift package update
   ```

2. **Xcode Integration**
   - File → Add Package Dependencies
   - Clean build folder
   - Reset package caches

3. **Version Conflicts**
   - Check Package.resolved
   - Update constraints
   - Use exact versions if needed

### Performance Impact

Monitor app metrics:
- Launch time
- Memory usage
- Binary size
- Network requests

## Future Considerations

### Potential Additions

1. **Analytics**: TelemetryDeck (privacy-focused)
2. **Crash Reporting**: Sentry or Crashlytics
3. **A/B Testing**: PostHog
4. **Deep Linking**: Branch or native

### Removal Candidates

Regular review for:
- Unused features
- Native replacements
- Maintenance burden
- Performance impact

## Conclusion

This dependency strategy balances functionality with maintainability. We prefer native iOS frameworks and only add external dependencies when they provide significant value. Regular reviews ensure our dependency tree remains lean and secure.