# Repository Pattern

## Overview

We're migrating to a Repository pattern to improve separation of concerns and make the codebase more maintainable. This pattern provides a clean abstraction between the API layer and the business logic.

## Why Repository Pattern?

1. **Separation of Concerns** - Models don't need to know about API details
2. **Testability** - Easy to mock repositories for testing
3. **Flexibility** - Can switch between API and local data sources
4. **Type Safety** - Repositories handle API type conversions
5. **Error Handling** - Centralized error transformation

## Architecture

```
┌─────────────────┐
│   View (UI)     │
├─────────────────┤
│ Model (@Observable) │
├─────────────────┤
│   Repository    │
├─────────────────┤
│ API Client │ DB │
└─────────────────┘
```

## Implementation Guidelines

### Repository Structure

```swift
// Repository Protocol
protocol UserRepositoryProtocol {
    func getCurrentUser() async throws -> User
    func getUser(by id: String) async throws -> User
    func updateUser(_ user: User) async throws -> User
}

// Implementation
public class UserRepository: UserRepositoryProtocol {
    private let apiClient: APIClient
    
    public init(apiClient: APIClient) {
        self.apiClient = apiClient
    }
    
    public func getCurrentUser() async throws -> User {
        let client = await apiClient.generatedClient
        let response = try await client.auth_me()
        
        // Extract and transform the response
        if case .ok(let okResponse) = response,
           case .json(let jsonPayload) = okResponse.body {
            return User(from: jsonPayload.user)
        }
        
        throw RepositoryError.invalidResponse
    }
}
```

### Model Usage

```swift
// ❌ Don't do this - Direct API access
@Observable
class ProfileModel {
    func loadUser() async {
        let client = await apiClient.generatedClient
        let response = try await client.auth_me()
        // ... handle response
    }
}

// ✅ Do this - Use repository
@Observable
class ProfileModel {
    private let userRepository: UserRepository
    
    init(userRepository: UserRepository = UserRepository(apiClient: APIClient.shared)) {
        self.userRepository = userRepository
    }
    
    func loadUser() async {
        do {
            user = try await userRepository.getCurrentUser()
        } catch {
            self.error = error
        }
    }
}
```

## Current Repositories

### UserRepository
- `getCurrentUser()` - Fetch authenticated user
- `getUser(by:)` - Fetch user by ID
- `getUserStats(for:)` - Fetch detailed user statistics

### AchievementsRepository
- `getCurrentUserBadges()` - Fetch user's achievements
- `getAchievementDetails(id:)` - Get specific achievement info

### FeedRepository
- `getFeed(type:cursor:)` - Fetch activity feed
- `refreshFeed()` - Force refresh from API

### BottleRepository
- `searchBottles(query:)` - Search bottle database
- `getBottle(id:)` - Get bottle details
- `getBottleExtendedInfo(id:)` - Get pricing, AI descriptions

### TastingRepository
- `createTasting(_:)` - Create new tasting with offline support
- `getTasting(id:)` - Get tasting details
- `updateTasting(_:)` - Update existing tasting

## Type Conversion

Repositories handle the conversion between API types and app models:

```swift
extension User {
    init(from apiUser: Components.Schemas.User) {
        self.id = String(apiUser.id)  // API uses Double for IDs
        self.email = apiUser.email ?? ""
        self.username = apiUser.username
        self.verified = apiUser.verified ?? false
        self.admin = apiUser.admin ?? false
        self.mod = apiUser.mod ?? false
    }
}
```

## Error Handling

```swift
enum RepositoryError: LocalizedError {
    case invalidResponse
    case notAuthenticated
    case networkError(Error)
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .notAuthenticated:
            return "Please log in to continue"
        case .networkError:
            return "Network connection error"
        case .apiError(let message):
            return message
        }
    }
}
```

## Testing

Repositories make testing much easier:

```swift
// Mock repository for testing
class MockUserRepository: UserRepositoryProtocol {
    var getCurrentUserResult: Result<User, Error> = .success(User.mock)
    
    func getCurrentUser() async throws -> User {
        try getCurrentUserResult.get()
    }
}

// Test
func testProfileLoading() async {
    let mockRepo = MockUserRepository()
    let model = ProfileModel(userRepository: mockRepo)
    
    await model.loadUser()
    
    XCTAssertEqual(model.user?.id, User.mock.id)
}
```

## Migration Strategy

1. **Phase 1**: Create repositories for new features
2. **Phase 2**: Migrate existing direct API calls to repositories
3. **Phase 3**: Add offline support to repositories
4. **Phase 4**: Implement caching strategies

## Best Practices

1. **One Repository per Domain** - UserRepository, BottleRepository, etc.
2. **Protocol-First** - Define protocol before implementation
3. **Async/Await** - Use modern concurrency throughout
4. **Error Transformation** - Convert API errors to user-friendly messages
5. **Type Safety** - Handle API type quirks (Double IDs, nullable fields)
6. **Dependency Injection** - Pass repositories to models, don't hardcode

## Common Patterns

### Paginated Results
```swift
struct PagedResult<T> {
    let items: [T]
    let cursor: String?
    let hasMore: Bool
}

func getFeed(cursor: String? = nil) async throws -> PagedResult<Tasting>
```

### Offline Queue
```swift
func createTasting(_ input: CreateTastingInput) async throws -> Tasting {
    // Create local record first
    let localTasting = Tasting(from: input)
    try await database.insert(localTasting)
    
    // Queue for sync
    try await syncQueue.add(.createTasting(localTasting))
    
    // Attempt immediate sync
    Task {
        try? await syncToAPI(localTasting)
    }
    
    return localTasting
}
```

### Cache Invalidation
```swift
func refreshUser() async throws -> User {
    let user = try await fetchFromAPI()
    try await database.update(user)
    notificationCenter.post(.userUpdated, object: user)
    return user
}
```