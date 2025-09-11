# Testing Strategy for Peated iOS

## Overview

This document outlines the testing approach for Peated iOS, focusing on the unique challenges of testing iOS applications with caching, async operations, and SwiftUI views.

## Testing Philosophy

- **Test Pyramid**: Heavy unit tests, moderate integration tests, light UI tests
- **Dependency Injection**: All dependencies should be injectable for testing
- **Protocol-Oriented**: Use protocols to enable mocking and test isolation
- **Async-First**: Design tests for async/await patterns from the start
- **Behavior-Driven**: Test behaviors and outcomes, not implementation details

## Testing Frameworks

- **Primary**: Swift Testing (iOS 18+) - Apple's modern testing framework
- **UI Testing**: XCUITest for end-to-end flows
- **Mocking**: Custom mocks using protocols (no third-party frameworks)
- **View Testing**: ViewInspector for SwiftUI component testing

## Testing Layers

### 1. Unit Tests (70% of test coverage)

#### Model Layer Testing
Test `@Observable` models like `FeedModel`:

```swift
@Test("FeedModel caches data correctly")
func testFeedCaching() async throws {
    // Given
    let mockRepository = MockFeedRepository()
    let model = FeedModel(feedRepository: mockRepository)
    
    mockRepository.mockFeedPage = FeedPage(
        tastings: [TastingFeedItem.sample1],
        cursor: "123", 
        hasMore: true
    )
    
    // When - Initial load
    await model.switchFeedType(.friends)
    let firstCallCount = mockRepository.callCount
    
    // Switch away and back to test caching
    await model.switchFeedType(.personal)
    await model.switchFeedType(.friends)
    let secondCallCount = mockRepository.callCount
    
    // Then
    #expect(firstCallCount == 1)
    #expect(secondCallCount == 1) // Should use cache
    #expect(model.tastings.count == 1)
}
```

**Key Testing Patterns:**
- Cache hit/miss scenarios
- Cache expiration logic
- Background refresh behavior
- Error handling and recovery
- State transitions

#### Repository Layer Testing
Test API integration and data transformation:

```swift
@Test("FeedRepository transforms API data correctly")
func testFeedRepositoryTransformation() async throws {
    // Given
    let mockAPIClient = MockAPIClient()
    let repository = FeedRepository(apiClient: mockAPIClient)
    
    mockAPIClient.mockResponse = Operations.Tastings_list.Output.ok(.init(
        body: .json(.init(results: [MockAPIData.sampleTasting]))
    ))
    
    // When
    let feedPage = try await repository.getFeed(type: .friends, cursor: nil)
    
    // Then
    #expect(feedPage.tastings.count == 1)
    #expect(feedPage.tastings.first?.bottleName == "Expected Bottle Name")
}
```

**Key Testing Areas:**
- API response transformation
- Error handling and retries
- Cursor-based pagination
- Feed type filtering

### 2. Integration Tests (20% of test coverage)

#### Model + Repository Integration
Test the full data flow without UI:

```swift
@Test("End-to-end feed loading with caching")
func testFeedLoadingIntegration() async throws {
    // Given
    let testAPI = TestAPIClient(responses: [
        .friends: MockFeedResponse.friendsData,
        .personal: MockFeedResponse.personalData
    ])
    let repository = FeedRepository(apiClient: testAPI)
    let model = FeedModel(feedRepository: repository)
    
    // When - Load friends feed
    await model.switchFeedType(.friends)
    let friendsLoadTime = testAPI.lastCallTime
    
    // Switch to personal
    await model.switchFeedType(.personal)
    
    // Switch back to friends (should use cache)
    await model.switchFeedType(.friends)
    let cachedAccessTime = testAPI.lastCallTime
    
    // Then
    #expect(friendsLoadTime != cachedAccessTime) // No new API call
    #expect(model.tastings.isNotEmpty)
}
```

#### Cache Behavior Testing
Test cache expiration and refresh logic:

```swift
@Test("Cache expiration triggers background refresh")
func testCacheExpiration() async throws {
    // Given
    let mockClock = MockClock()
    let model = FeedModel(
        feedRepository: MockFeedRepository(),
        clock: mockClock
    )
    
    // Load initial data
    await model.switchFeedType(.friends)
    
    // When - Simulate time passing
    mockClock.advance(by: .minutes(3)) // Past stale threshold
    await model.switchFeedType(.personal)
    await model.switchFeedType(.friends) // Should trigger background refresh
    
    // Then
    #expect(model.tastings.isNotEmpty) // Shows cached data immediately
    
    // Wait for background refresh
    try await Task.sleep(for: .milliseconds(100))
    #expect(mockRepository.refreshCallCount == 1)
}
```

### 3. UI Tests (10% of test coverage)

#### SwiftUI View Testing
Test view behavior and state rendering:

```swift
@Test("FeedView shows loading state initially")
func testFeedViewLoadingState() throws {
    // Given
    let model = FeedModel(feedRepository: SlowMockRepository())
    let view = FeedView(model: model)
    
    // When
    let inspection = try view.inspect()
    
    // Then
    #expect(try inspection.find(LoadingView.self).exists())
    #expect(try inspection.find(text: "Loading...").exists())
}

@Test("Pull to refresh updates content")
func testPullToRefresh() async throws {
    // Given
    let mockRepo = MockFeedRepository()
    let model = FeedModel(feedRepository: mockRepo)
    let view = FeedView(model: model)
    
    // Load initial content
    await model.loadFeed()
    
    // When - Simulate pull to refresh
    mockRepo.mockFeedPage = FeedPage(
        tastings: [TastingFeedItem.sample2],
        cursor: nil,
        hasMore: false
    )
    
    let scrollView = try view.inspect().find(ScrollView.self)
    try await scrollView.callOnRefresh()
    
    // Then
    #expect(model.tastings.first?.id == TastingFeedItem.sample2.id)
    #expect(mockRepo.refreshCallCount == 1)
}
```

#### End-to-End UI Tests
Test critical user journeys:

```swift
class FeedUITests: XCTestCase {
    func testFeedTabSwitchingCaching() throws {
        let app = XCUIApplication()
        app.launch()
        
        // Wait for Friends feed to load
        let friendsFeed = app.staticTexts["Friends"]
        XCTAssertTrue(friendsFeed.waitForExistence(timeout: 5))
        
        // Switch to You tab
        app.buttons["You"].tap()
        XCTAssertTrue(app.staticTexts["You"].exists)
        
        // Switch back to Friends (should be instant)
        let switchStartTime = Date()
        app.buttons["Friends"].tap()
        
        // Content should appear immediately (cached)
        XCTAssertTrue(friendsFeed.waitForExistence(timeout: 1))
        let switchDuration = Date().timeIntervalSince(switchStartTime)
        XCTAssertLessThan(switchDuration, 0.5) // Should be near-instant
    }
}
```

## Mock Strategy

### Repository Mocks
```swift
protocol FeedRepositoryProtocol {
    func getFeed(type: FeedType, cursor: String?, limit: Int) async throws -> FeedPage
    func refreshFeed(type: FeedType) async throws -> FeedPage
}

class MockFeedRepository: FeedRepositoryProtocol {
    var mockFeedPage: FeedPage?
    var mockError: Error?
    var callCount = 0
    var refreshCallCount = 0
    var lastFeedType: FeedType?
    
    func getFeed(type: FeedType, cursor: String?, limit: Int) async throws -> FeedPage {
        callCount += 1
        lastFeedType = type
        
        if let error = mockError {
            throw error
        }
        
        return mockFeedPage ?? FeedPage.empty
    }
    
    func refreshFeed(type: FeedType) async throws -> FeedPage {
        refreshCallCount += 1
        return try await getFeed(type: type, cursor: nil, limit: 20)
    }
}
```

### API Client Mocks
```swift
class MockAPIClient: APIClient {
    var responses: [String: Any] = [:]
    var networkDelay: TimeInterval = 0
    var shouldFail = false
    var callCount = 0
    var lastCallTime: Date?
    
    override func tastings_list(query: Operations.Tastings_list.Input.Query) async throws -> Operations.Tastings_list.Output {
        callCount += 1
        lastCallTime = Date()
        
        if networkDelay > 0 {
            try await Task.sleep(for: .seconds(networkDelay))
        }
        
        if shouldFail {
            throw APIError.networkError
        }
        
        guard let mockResponse = responses["tastings_list"] else {
            throw APIError.notFound
        }
        
        return mockResponse as! Operations.Tastings_list.Output
    }
}
```

### Time/Clock Mocking
```swift
protocol ClockProtocol {
    func now() -> Date
    func sleep(for duration: Duration) async throws
}

class SystemClock: ClockProtocol {
    func now() -> Date { Date() }
    func sleep(for duration: Duration) async throws {
        try await Task.sleep(for: duration)
    }
}

class MockClock: ClockProtocol {
    private var currentTime = Date()
    
    func now() -> Date { currentTime }
    
    func advance(by interval: TimeInterval) {
        currentTime.addTimeInterval(interval)
    }
    
    func sleep(for duration: Duration) async throws {
        // Instant for tests
    }
}

// Update FeedModel to use ClockProtocol
class FeedModel {
    private let clock: ClockProtocol
    
    init(feedRepository: FeedRepositoryProtocol, clock: ClockProtocol = SystemClock()) {
        self.feedRepository = feedRepository
        self.clock = clock
    }
    
    private var isExpired: Bool {
        guard let lastUpdated = lastUpdated else { return true }
        return clock.now().timeIntervalSince(lastUpdated) > 300
    }
}
```

## Test Data Builders

### Builder Pattern for Test Data
```swift
extension TastingFeedItem {
    static func builder() -> TastingFeedItemBuilder {
        TastingFeedItemBuilder()
    }
    
    static var sample1: TastingFeedItem {
        builder()
            .withId("1")
            .withBottleName("Lagavulin 16")
            .withUsername("testuser")
            .withRating(4.5)
            .build()
    }
}

class TastingFeedItemBuilder {
    private var id = UUID().uuidString
    private var rating = 4.0
    private var bottleName = "Default Whisky"
    private var username = "testuser"
    private var createdAt = Date()
    
    func withId(_ id: String) -> Self {
        self.id = id
        return self
    }
    
    func withRating(_ rating: Double) -> Self {
        self.rating = rating
        return self
    }
    
    func withBottleName(_ name: String) -> Self {
        self.bottleName = name
        return self
    }
    
    func withUsername(_ username: String) -> Self {
        self.username = username
        return self
    }
    
    func withCreatedAt(_ date: Date) -> Self {
        self.createdAt = date
        return self
    }
    
    func build() -> TastingFeedItem {
        TastingFeedItem(
            id: id,
            rating: rating,
            notes: nil,
            servingStyle: nil,
            imageUrl: nil,
            createdAt: createdAt,
            userId: "user1",
            username: username,
            userDisplayName: nil,
            userAvatarUrl: nil,
            bottleId: "bottle1",
            bottleName: bottleName,
            bottleBrandName: "Test Distillery",
            bottleCategory: "scotch",
            bottleImageUrl: nil,
            toastCount: 0,
            commentCount: 0,
            hasToasted: false,
            tags: [],
            location: nil,
            friendUsernames: []
        )
    }
}
```

### Preset Test Scenarios
```swift
struct TestScenarios {
    static let emptyFeed = FeedPage(tastings: [], cursor: nil, hasMore: false)
    
    static let singleItemFeed = FeedPage(
        tastings: [TastingFeedItem.sample1],
        cursor: "123",
        hasMore: true
    )
    
    static let fullPageFeed = FeedPage(
        tastings: Array(1...20).map { TastingFeedItem.builder().withId("\($0)").build() },
        cursor: "140",
        hasMore: true
    )
    
    static let networkError = APIError.networkUnavailable
    static let authError = APIError.unauthorized
}
```

## Performance Testing

### Cache Performance Tests
```swift
@Test("Cache access is faster than network calls")
func testCachePerformance() async throws {
    let repository = FeedRepository(apiClient: SlowAPIClient(delay: 1.0))
    let model = FeedModel(feedRepository: repository)
    
    // First load (network)
    let networkStartTime = Date()
    await model.switchFeedType(.friends)
    let networkDuration = Date().timeIntervalSince(networkStartTime)
    
    // Switch away and back (cache)
    await model.switchFeedType(.personal)
    
    let cacheStartTime = Date()
    await model.switchFeedType(.friends)
    let cacheDuration = Date().timeIntervalSince(cacheStartTime)
    
    #expect(cacheDuration < networkDuration / 10) // Cache should be 10x faster
    #expect(cacheDuration < 0.1) // Cache access under 100ms
}
```

### Memory Usage Tests
```swift
@Test("Feed cache doesn't grow unbounded")
func testCacheMemoryUsage() async throws {
    let model = FeedModel(feedRepository: MockFeedRepository())
    
    // Load large amounts of data
    for feedType in FeedType.allCases {
        await model.switchFeedType(feedType)
        // Simulate loading many pages
        for _ in 1...10 {
            await model.loadMoreIfNeeded(currentItem: model.tastings.last!)
        }
    }
    
    // Memory usage should be reasonable (implementation-dependent)
    let memoryUsage = getMemoryUsage()
    #expect(memoryUsage < 50_000_000) // Under 50MB
}
```

## Test Organization

### Directory Structure
```
Tests/
├── PeatedCoreTests/
│   ├── Models/
│   │   ├── FeedModelTests.swift
│   │   ├── FeedModelCachingTests.swift
│   │   ├── FeedModelErrorHandlingTests.swift
│   │   └── TastingFeedItemTests.swift
│   ├── Repositories/
│   │   ├── FeedRepositoryTests.swift
│   │   ├── FeedRepositoryIntegrationTests.swift
│   │   └── APITransformationTests.swift
│   ├── Services/
│   │   ├── AuthenticationManagerTests.swift
│   │   └── CacheServiceTests.swift
│   ├── Utilities/
│   │   ├── DateExtensionsTests.swift
│   │   └── StringExtensionsTests.swift
│   └── TestSupport/
│       ├── Mocks/
│       │   ├── MockFeedRepository.swift
│       │   ├── MockAPIClient.swift
│       │   └── MockClock.swift
│       ├── Builders/
│       │   ├── TastingFeedItemBuilder.swift
│       │   └── FeedPageBuilder.swift
│       ├── TestData/
│       │   ├── SampleData.swift
│       │   └── TestScenarios.swift
│       └── Extensions/
│           ├── XCTestCase+Async.swift
│           └── TestHelpers.swift
├── PeatedUITests/
│   ├── FeedViewTests.swift
│   ├── PullToRefreshTests.swift
│   ├── TabSwitchingTests.swift
│   └── ErrorStateTests.swift
├── PeatedIntegrationTests/
│   ├── EndToEndFeedTests.swift
│   ├── CacheIntegrationTests.swift
│   └── PerformanceTests.swift
└── PeatedUITests/ (XCUITest)
    ├── CriticalUserJourneyTests.swift
    ├── AccessibilityTests.swift
    └── PerformanceUITests.swift
```

### Test Categories and Tags
```swift
// Use test tags for organization
@Test("Cache hit returns immediately", .tags(.caching, .performance))
func testCacheHit() async throws { }

@Test("Network error shows error state", .tags(.errorHandling, .networking))
func testNetworkError() async throws { }

@Test("Pull to refresh updates feed", .tags(.ui, .refresh))
func testPullToRefresh() async throws { }

extension Tag {
    @Tag static var caching: Self
    @Tag static var networking: Self
    @Tag static var errorHandling: Self
    @Tag static var performance: Self
    @Tag static var ui: Self
    @Tag static var refresh: Self
}
```

## Running Tests

### Test Commands
```bash
# Run all tests
swift test

# Run specific test categories
swift test --filter tag:caching
swift test --filter tag:performance

# Run tests with coverage
swift test --enable-code-coverage

# Run UI tests
xcodebuild test -project Peated.xcodeproj -scheme Peated -destination 'platform=iOS Simulator,name=iPhone 16'
```

### CI/CD Integration
```yaml
# GitHub Actions example
- name: Run Unit Tests
  run: swift test --enable-code-coverage

- name: Run UI Tests
  run: |
    xcodebuild test \
      -project Peated.xcodeproj \
      -scheme Peated \
      -destination 'platform=iOS Simulator,name=iPhone 16' \
      -resultBundlePath TestResults.xcresult

- name: Check Test Coverage
  run: |
    xcrun xccov view TestResults.xcresult --report --only-targets
```

## Testing Best Practices

### Do's
- ✅ Test behaviors, not implementation details
- ✅ Use dependency injection for all external dependencies
- ✅ Write fast, isolated unit tests
- ✅ Test error scenarios as thoroughly as happy paths
- ✅ Use descriptive test names that explain the scenario
- ✅ Follow Given-When-Then structure in tests
- ✅ Mock time-dependent operations
- ✅ Test async operations properly with async/await

### Don'ts
- ❌ Don't test private methods directly
- ❌ Don't use real network calls in unit tests
- ❌ Don't create tests that depend on external state
- ❌ Don't ignore flaky tests - fix them immediately
- ❌ Don't test UI layout details that change frequently
- ❌ Don't use sleep() for timing - use proper async testing
- ❌ Don't mock what you don't own (system frameworks)

## Coverage Goals

- **Overall**: 80%+ code coverage
- **Models**: 90%+ (critical business logic)
- **Repositories**: 85%+ (data layer reliability)
- **Views**: 60%+ (focus on critical interactions)
- **UI Tests**: Cover top 5 user journeys

## Maintenance

- Review and update mocks when APIs change
- Add new test scenarios for each bug found
- Refactor tests when refactoring production code
- Keep test data builders up to date with model changes
- Regularly review and improve slow tests
- Monitor test coverage and address gaps

This testing strategy ensures reliable, maintainable tests that give confidence in the caching behavior and overall app functionality.