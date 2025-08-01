# Technology Stack

## Core Technologies

### Platform
- **Target**: iOS 17.0+
- **Language**: Swift 5.9+
- **UI Framework**: SwiftUI
- **Minimum Device**: iPhone 11 and newer

### Key Frameworks

#### SwiftUI
- Modern declarative UI framework
- Native performance and platform features
- Built-in accessibility support
- Smooth animations and transitions

#### SQLite
- Lightweight, embedded database
- Direct SQL control for optimization
- Proven reliability and performance
- Full offline support with sync queue

#### Swift Concurrency
- async/await for asynchronous operations
- Structured concurrency with Task groups
- Actor isolation for thread safety
- AsyncSequence for reactive streams

## Dependencies

### Database
- **SQLite.swift**: Type-safe SQLite wrapper
  - Version: 0.14.0+
  - Swift-friendly query builder
  - Automatic migrations
  - Full-text search support

### API Integration
- **OpenAPI Generator**: Swift client generation
  - Version: 7.x
  - Template: swift5
  - Generates type-safe models and networking

### Networking
- **URLSession**: Native HTTP client
  - Custom configuration for auth headers
  - Background session for uploads
  - Progress tracking for images

### Security
- **Keychain Services**: Secure credential storage
  - OAuth tokens
  - User preferences
  - Biometric authentication

### Image Handling
- **Core Image**: Image processing
  - Filters for user photos
  - Thumbnail generation
  - HEIC to JPEG conversion

### Location Services
- **Core Location**: Check-in locations
  - Current location for venues
  - Location search
  - Privacy-preserving

## Development Tools

### Build System
- **Xcode 15.0+**: IDE and build tools
- **Swift Package Manager**: Dependency management
- **xcodebuild**: CI/CD automation

### Code Generation
```bash
# OpenAPI client generation
openapi-generator generate \
  -i peated-api.yaml \
  -g swift5 \
  -o ./PeatedAPI \
  --additional-properties=library=urlsession,projectName=PeatedAPI
```

### Testing
- **Swift Testing**: Primary testing framework (iOS 17+)
- **XCUITest**: UI automation tests only
- **XCTest**: Legacy tests being migrated

## Architecture Patterns

### MV (Model-View) with @Observable
```swift
// Model (in PeatedCore)
@Observable
public class FeedModel {
    public var tastings: [Tasting] = []
    public var isLoading = false
    private let repository: FeedRepository
    
    public init(repository: FeedRepository = FeedRepositoryImpl()) {
        self.repository = repository
    }
    
    public func loadFeed() async {
        isLoading = true
        tastings = await repository.getFeed()
        isLoading = false
    }
}

// View (in main app)
struct FeedView: View {
    @State private var model = FeedModel()
    
    var body: some View {
        List(model.tastings) { tasting in
            TastingCard(tasting: tasting)
        }
        .task {
            await model.loadFeed()
        }
        .overlay {
            if model.isLoading {
                ProgressView()
            }
        }
    }
}
```

### Repository Pattern
```swift
protocol FeedRepository {
    func getFeed() async -> [Tasting]
    func createTasting(_ tasting: Tasting) async throws
}

class FeedRepositoryImpl: FeedRepository {
    private let apiClient: PeatedAPI
    private let db: Connection
    
    func getFeed() async -> [Tasting] {
        // Check SQLite cache first, then API
        // Update cache with API response
    }
}
```

### Dependency Injection
```swift
// Simple initializer injection
@Observable
class TastingModel {
    private let repository: TastingRepository
    
    init(repository: TastingRepository = TastingRepositoryImpl()) {
        self.repository = repository
    }
}
```

## Data Flow

### API → SQLite → UI
1. API responses deserialize to Codable models
2. Transform to simplified SQLite records
3. Models query and transform data
4. SwiftUI views update via @Observable

### Offline Queue
```swift
struct PendingAction: Codable {
    let id: UUID
    let type: ActionType
    let payload: Data
    let createdAt: Date
    var retryCount: Int = 0
}

class OfflineQueue {
    private let db: Connection
    
    func enqueue(_ action: PendingAction) throws {
        try db.run(pendingActions.insert(action))
    }
    
    func processQueue() async throws {
        let actions = try db.prepare(pendingActions.order(createdAt))
        for action in actions {
            await processAction(action)
        }
    }
}
```

## Performance Considerations

### Memory Management
- Lazy loading for images
- View recycling in lists
- Manual cache eviction for SQLite
- Image cache size limits

### Network Optimization
- Batch API requests where possible
- Compress image uploads
- Cache control headers
- Request debouncing

### UI Responsiveness
- Main actor isolation for UI updates
- Background processing for heavy tasks
- Incremental loading for large datasets
- Skeleton screens during loads

## Platform Integration

### iOS Features
- **Push Notifications**: APNs for social updates
- **Share Extensions**: Share to Peated
- **Widgets** (Future): Latest tastings
- **Shortcuts** (Future): Quick check-in

### Privacy
- **App Tracking Transparency**: User consent
- **Location Privacy**: When-in-use only
- **Photo Library**: Limited access
- **Camera**: Optional for barcode scanning

## Build Configuration

### Environments
```swift
enum Environment {
    case development
    case staging  
    case production
    
    var apiBaseURL: URL {
        switch self {
        case .development: 
            return URL(string: "https://dev-api.peated.com")!
        case .staging:
            return URL(string: "https://staging-api.peated.com")!
        case .production:
            return URL(string: "https://api.peated.com")!
        }
    }
}
```

### Feature Flags
```swift
struct FeatureFlags {
    static let barcodeScanning = true
    static let socialSharing = true
    static let advancedFilters = false
}
```

## Future Considerations

### Potential Additions
- **TipKit**: Onboarding and feature discovery
- **StoreKit 2**: Premium features
- **CloudKit**: Cross-device sync
- **WidgetKit**: Home screen widgets
- **App Clips**: Quick venue check-ins

### Performance Monitoring
- **MetricKit**: Performance metrics
- **OSLog**: Structured logging
- **Instruments**: Profiling and optimization