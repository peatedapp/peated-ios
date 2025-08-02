# PeatedCore Tests

This directory contains tests for the PeatedCore package, focusing on testing the caching behavior, repository logic, and model functionality.

## Test Structure

```
Tests/
├── PeatedCoreTests/
│   ├── Models/
│   │   └── FeedModelCachingTests.swift     # Main caching behavior tests
│   └── TestSupport/
│       ├── MockFeedRepository.swift        # Mock repository for testing
│       └── TastingFeedItemBuilder.swift    # Test data builders
└── README.md
```

## Running Tests

### Via Swift CLI (from PeatedCore directory)

```bash
# Run all tests
swift test

# Run specific test class
swift test --filter FeedModelCachingTests

# Run specific test function
swift test --filter "testFeedDataIsCached"

# Run with verbose output
swift test --verbose

# Run with code coverage
swift test --enable-code-coverage
```

### Via Xcode

1. Open the `Peated.xcodeproj` project
2. Select the PeatedCore scheme
3. Navigate to the test files in the Project Navigator
4. Click the diamond icon next to any test function to run it
5. Use ⌘+U to run all tests

## Test Examples

### Basic Cache Test
```swift
@Test("Feed data is cached after initial load")
func testFeedDataIsCached() async throws {
    // Given
    let mockRepository = MockFeedRepository()
    let model = FeedModel(feedRepository: mockRepository)
    mockRepository.mockFeedPage = .singleItem
    
    // When - Load friends feed for the first time
    await model.switchFeedType(.friends)
    let firstCallCount = mockRepository.getFeedCallCount
    
    // Switch to a different feed type and back
    await model.switchFeedType(.personal)
    await model.switchFeedType(.friends)
    let secondCallCount = mockRepository.getFeedCallCount
    
    // Then - Should use cache on second access
    #expect(firstCallCount == 1)
    #expect(secondCallCount == 1) // No additional API call
    #expect(model.tastings.count == 1)
}
```

### Pull-to-Refresh Test
```swift
@Test("Pull to refresh clears cache and loads fresh data")
func testPullToRefreshClearsCache() async throws {
    // Given - Load initial data
    let mockRepository = MockFeedRepository()
    let model = FeedModel(feedRepository: mockRepository)
    mockRepository.mockFeedPage = .singleItem
    await model.switchFeedType(.friends)
    
    // When - Simulate server data change and refresh
    mockRepository.mockFeedPage = .multipleItems
    await model.refreshCurrentFeed()
    
    // Then - Should show updated data
    #expect(model.tastings.count == 3) // multipleItems has 3 items
    #expect(mockRepository.refreshFeedCallCount == 1)
}
```

## Test Data

### Using Builders
```swift
let customTasting = TastingFeedItem.builder()
    .withId("custom1")
    .withBottleName("Ardbeg 10")
    .withBrandName("Ardbeg")
    .withUsername("peat_lover")
    .withRating(4.7)
    .withNotes("Intensely smoky with maritime notes")
    .withTags(["peaty", "smoky", "maritime"])
    .build()
```

### Predefined Samples
```swift
// Quick samples for common scenarios
let sample1 = TastingFeedItem.sample1  // Lagavulin 16
let sample2 = TastingFeedItem.sample2  // Glenfiddich 12
let sample3 = TastingFeedItem.sample3  // Macallan 18

// Feed pages
let emptyFeed = FeedPage.empty
let singleItemFeed = FeedPage.singleItem
let multipleItemsFeed = FeedPage.multipleItems
let fullPageFeed = FeedPage.fullPage  // 20 items for pagination testing
```

## Mock Repository Usage

### Basic Setup
```swift
let mockRepository = MockFeedRepository()
let model = FeedModel(feedRepository: mockRepository)

// Configure response
mockRepository.mockFeedPage = .singleItem

// Configure network behavior
mockRepository.networkDelay = 0.1  // Simulate slow network
mockRepository.mockError = APIError.networkUnavailable  // Simulate error
```

### Call Tracking
```swift
// Check how many times API was called
#expect(mockRepository.getFeedCallCount == 2)
#expect(mockRepository.refreshFeedCallCount == 1)

// Check what was called
#expect(mockRepository.wasGetFeedCalled(for: .friends))
#expect(mockRepository.lastFeedType == .personal)

// Detailed call history
let friendsCalls = mockRepository.getFeedCalls.filter { $0.type == .friends }
#expect(friendsCalls.count == 1)
```

## Performance Testing

```swift
@Test("Cache access is significantly faster than network")
func testCachePerformance() async throws {
    let mockRepository = MockFeedRepository()
    mockRepository.networkDelay = 0.2  // 200ms network delay
    
    let model = FeedModel(feedRepository: mockRepository)
    
    // Time network access
    let networkStart = Date()
    await model.switchFeedType(.friends)
    let networkTime = Date().timeIntervalSince(networkStart)
    
    // Time cache access
    await model.switchFeedType(.personal)
    let cacheStart = Date()
    await model.switchFeedType(.friends)
    let cacheTime = Date().timeIntervalSince(cacheStart)
    
    #expect(cacheTime < networkTime / 2)  // Cache should be 2x faster
}
```

## Best Practices

1. **Always reset mocks** between tests to avoid state pollution
2. **Use builders** for complex test data instead of hardcoded values
3. **Test both success and failure cases** for robust coverage
4. **Test timing-sensitive operations** like cache expiration
5. **Use descriptive test names** that explain the scenario being tested
6. **Follow Given-When-Then** structure for clarity

## Debugging Tests

### Common Issues

1. **Test timeout**: Large dependencies can cause slow builds
   ```bash
   swift test --timeout 300  # Increase timeout to 5 minutes
   ```

2. **Memory issues**: Tests holding references
   ```swift
   // Always let mocks go out of scope
   func testSomething() async throws {
       let mockRepository = MockFeedRepository()
       // ... test code ...
   } // mockRepository deallocated here
   ```

3. **Async timing issues**: 
   ```swift
   // Use proper async/await instead of sleep
   await model.switchFeedType(.friends)  // ✅ Good
   // Thread.sleep(1.0)  // ❌ Bad
   ```

### Debugging Tips

1. **Add print statements** in mock methods to see call order
2. **Use breakpoints** in test methods and mock implementations
3. **Check call history** in MockFeedRepository for detailed tracking
4. **Test one scenario at a time** by commenting out other assertions

## Coverage Goals

- **Models**: 90%+ coverage (critical business logic)
- **Repositories**: 85%+ coverage (data layer)
- **Cache Logic**: 95%+ coverage (core feature)

Run with coverage:
```bash
swift test --enable-code-coverage
```