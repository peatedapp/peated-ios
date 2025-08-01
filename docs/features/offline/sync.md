# Offline Support & Sync

## Overview

Peated implements a comprehensive offline-first architecture that ensures users can continue using core features without an internet connection. All data is cached locally using SwiftData, with intelligent sync mechanisms to handle updates when connectivity is restored.

## Offline Architecture

```
┌─────────────────────────────────────────┐
│            User Interface               │
├─────────────────────────────────────────┤
│           View Models                   │
├─────────────────────────────────────────┤
│         Repository Layer                │
├─────────────────────────────────────────┤
│   Sync Manager  │  Mutation Queue       │
├─────────────────────────────────────────┤
│      SwiftData (Local Storage)         │
├─────────────────────────────────────────┤
│    Network Monitor │ API Client        │
└─────────────────────────────────────────┘
```

## Core Components

### Network Monitor

```swift
import Network
import Combine

class NetworkMonitor: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var isConnected = true
    @Published var connectionType: ConnectionType = .unknown
    @Published var isExpensive = false
    
    enum ConnectionType {
        case wifi
        case cellular
        case wired
        case unknown
    }
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.isExpensive = path.isExpensive
                self?.updateConnectionType(path)
            }
        }
        monitor.start(queue: queue)
    }
    
    private func updateConnectionType(_ path: NWPath) {
        if path.usesInterfaceType(.wifi) {
            connectionType = .wifi
        } else if path.usesInterfaceType(.cellular) {
            connectionType = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            connectionType = .wired
        } else {
            connectionType = .unknown
        }
    }
}
```

### Mutation Queue

```swift
import SwiftData

@Model
final class PendingMutation {
    @Attribute(.unique) var id: UUID
    var type: MutationType
    var entityId: String
    var payload: Data
    var retryCount: Int = 0
    var maxRetries: Int = 3
    var createdAt: Date
    var lastAttemptAt: Date?
    var error: String?
    var priority: MutationPriority = .normal
    
    init(type: MutationType, entityId: String, payload: Data, priority: MutationPriority = .normal) {
        self.id = UUID()
        self.type = type
        self.entityId = entityId
        self.payload = payload
        self.priority = priority
        self.createdAt = Date()
    }
}

enum MutationType: String, Codable {
    // Create operations
    case createTasting
    case createComment
    case createToast
    
    // Update operations
    case updateTasting
    case updateProfile
    case updateBottleRating
    
    // Delete operations
    case deleteTasting
    case deleteComment
    case deleteToast
    
    // Social operations
    case followUser
    case unfollowUser
    case blockUser
    
    // List operations
    case addToList
    case removeFromList
    case createList
    case updateList
}

enum MutationPriority: Int, Codable {
    case low = 0
    case normal = 1
    case high = 2
    case critical = 3
}
```

### Sync Manager

```swift
import SwiftData
import Combine

@MainActor
class SyncManager: ObservableObject {
    @Published var isSyncing = false
    @Published var pendingMutationsCount = 0
    @Published var lastSyncDate: Date?
    @Published var syncErrors: [SyncError] = []
    
    private let modelContext: ModelContext
    private let networkMonitor: NetworkMonitor
    private let apiClient: PeatedAPI
    private var syncTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    init(modelContext: ModelContext, networkMonitor: NetworkMonitor, apiClient: PeatedAPI) {
        self.modelContext = modelContext
        self.networkMonitor = networkMonitor
        self.apiClient = apiClient
        
        setupNetworkMonitoring()
        startPeriodicSync()
    }
    
    // MARK: - Network Monitoring
    private func setupNetworkMonitoring() {
        networkMonitor.$isConnected
            .removeDuplicates()
            .sink { [weak self] isConnected in
                if isConnected {
                    Task {
                        await self?.syncPendingMutations()
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Periodic Sync
    private func startPeriodicSync() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            Task { [weak self] in
                await self?.performFullSync()
            }
        }
    }
    
    // MARK: - Sync Operations
    func performFullSync() async {
        guard networkMonitor.isConnected else { return }
        
        isSyncing = true
        syncErrors.removeAll()
        
        // 1. Process pending mutations
        await syncPendingMutations()
        
        // 2. Fetch latest data
        await fetchLatestData()
        
        // 3. Clean up old data
        await cleanupOldData()
        
        lastSyncDate = Date()
        isSyncing = false
    }
    
    func syncPendingMutations() async {
        let descriptor = FetchDescriptor<PendingMutation>(
            predicate: #Predicate { $0.retryCount < $0.maxRetries },
            sortBy: [
                SortDescriptor(\.priority, order: .reverse),
                SortDescriptor(\.createdAt)
            ]
        )
        
        guard let mutations = try? modelContext.fetch(descriptor),
              !mutations.isEmpty else {
            pendingMutationsCount = 0
            return
        }
        
        pendingMutationsCount = mutations.count
        
        for mutation in mutations {
            do {
                try await processMutation(mutation)
                modelContext.delete(mutation)
                pendingMutationsCount -= 1
            } catch {
                await handleMutationError(mutation, error)
            }
        }
        
        try? modelContext.save()
    }
    
    private func processMutation(_ mutation: PendingMutation) async throws {
        mutation.lastAttemptAt = Date()
        
        switch mutation.type {
        case .createTasting:
            try await processCreateTasting(mutation)
        case .createComment:
            try await processCreateComment(mutation)
        case .createToast:
            try await processCreateToast(mutation)
        case .updateTasting:
            try await processUpdateTasting(mutation)
        case .deleteTasting:
            try await processDeleteTasting(mutation)
        // ... other mutation types
        default:
            break
        }
    }
    
    // MARK: - Mutation Processors
    private func processCreateTasting(_ mutation: PendingMutation) async throws {
        let request = try JSONDecoder().decode(CreateTastingRequest.self, from: mutation.payload)
        let response = try await apiClient.createTasting(request)
        
        // Update local tasting with server ID
        let predicate = #Predicate<Tasting> { $0.id == mutation.entityId }
        let descriptor = FetchDescriptor(predicate: predicate)
        
        if let localTasting = try? modelContext.fetch(descriptor).first {
            localTasting.id = response.id
            localTasting.syncStatus = .synced
            try modelContext.save()
        }
    }
    
    private func processCreateComment(_ mutation: PendingMutation) async throws {
        let request = try JSONDecoder().decode(CreateCommentRequest.self, from: mutation.payload)
        let response = try await apiClient.createComment(request)
        
        // Update local comment with server ID
        let predicate = #Predicate<Comment> { $0.id == mutation.entityId }
        let descriptor = FetchDescriptor(predicate: predicate)
        
        if let localComment = try? modelContext.fetch(descriptor).first {
            localComment.id = response.id
            try modelContext.save()
        }
    }
    
    // MARK: - Error Handling
    private func handleMutationError(_ mutation: PendingMutation, _ error: Error) async {
        mutation.retryCount += 1
        mutation.error = error.localizedDescription
        
        if mutation.retryCount >= mutation.maxRetries {
            syncErrors.append(SyncError(
                mutation: mutation,
                error: error,
                timestamp: Date()
            ))
            
            // Notify user of permanent failure
            await notifyMutationFailure(mutation)
        } else {
            // Schedule retry with exponential backoff
            let delay = pow(2.0, Double(mutation.retryCount)) * 60
            Task {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                await syncPendingMutations()
            }
        }
    }
    
    // MARK: - Data Fetching
    private func fetchLatestData() async {
        do {
            // Fetch latest feed
            await fetchLatestFeed()
            
            // Fetch user data
            await fetchUserData()
            
            // Fetch notifications
            await fetchNotifications()
        } catch {
            syncErrors.append(SyncError(
                mutation: nil,
                error: error,
                timestamp: Date()
            ))
        }
    }
    
    private func fetchLatestFeed() async {
        // Fetch latest tastings since last sync
        guard let lastSync = lastSyncDate else { return }
        
        do {
            let tastings = try await apiClient.getFeed(since: lastSync)
            
            for apiTasting in tastings {
                let predicate = #Predicate<Tasting> { $0.id == apiTasting.id }
                let descriptor = FetchDescriptor(predicate: predicate)
                
                if let existing = try? modelContext.fetch(descriptor).first {
                    existing.update(from: apiTasting)
                } else {
                    let newTasting = Tasting(from: apiTasting)
                    modelContext.insert(newTasting)
                }
            }
            
            try? modelContext.save()
        } catch {
            print("Failed to fetch latest feed: \(error)")
        }
    }
    
    // MARK: - Cleanup
    private func cleanupOldData() async {
        // Remove old cached data based on settings
        let cutoffDate = Date().addingTimeInterval(-30 * 24 * 60 * 60) // 30 days
        
        // Clean old tastings not in user's library
        let oldTastingsDescriptor = FetchDescriptor<Tasting>(
            predicate: #Predicate { tasting in
                tasting.createdAt < cutoffDate &&
                !tasting.bottle!.isWishlist &&
                !tasting.bottle!.hasHad
            }
        )
        
        if let oldTastings = try? modelContext.fetch(oldTastingsDescriptor) {
            for tasting in oldTastings {
                modelContext.delete(tasting)
            }
        }
        
        try? modelContext.save()
    }
}

// MARK: - Supporting Types
struct SyncError: Identifiable {
    let id = UUID()
    let mutation: PendingMutation?
    let error: Error
    let timestamp: Date
}
```

## Offline Capabilities

### Full Offline Support
- Browse previously loaded feed
- View tasting details and comments
- Access library and lists
- View bottle information
- Review personal statistics

### Create While Offline
- Add new tastings
- Write comments
- Toast tastings
- Manage lists
- Update profile

### Queued Actions
All mutations are queued and synced when online:
- Priority-based processing
- Automatic retry with backoff
- Conflict resolution
- Error recovery

## Data Caching Strategy

### Cache Policies

```swift
enum CachePolicy {
    case always           // Always cache (user data, library)
    case session         // Cache for session (search results)
    case temporary(TimeInterval)  // Cache with expiry
    case never           // Don't cache (sensitive data)
}

struct CacheConfiguration {
    static let policies: [String: CachePolicy] = [
        "user": .always,
        "library": .always,
        "feed": .temporary(300),        // 5 minutes
        "search": .session,
        "bottle": .temporary(3600),      // 1 hour
        "statistics": .temporary(1800)    // 30 minutes
    ]
}
```

### Storage Limits

```swift
class StorageManager {
    static let maxCacheSize: Int = 500 * 1024 * 1024  // 500 MB
    static let maxImageCacheSize: Int = 200 * 1024 * 1024  // 200 MB
    static let maxFeedItems: Int = 1000
    static let maxSearchResults: Int = 100
    
    func enforceStorageLimits() async {
        await trimFeedCache()
        await trimImageCache()
        await removeExpiredData()
    }
}
```

## Conflict Resolution

### Last Write Wins
Default strategy for most data:
- Server timestamp determines winner
- Local changes preserved in history

### Merge Strategy
For collaborative data:
- Lists merge additions
- Comments preserve all
- Ratings average if close

### User Choice
For conflicts requiring input:
- Present both versions
- Allow manual selection
- Remember preference

## Implementation Example

### Repository with Offline Support

```swift
class TastingRepository {
    private let modelContext: ModelContext
    private let apiClient: PeatedAPI
    private let syncManager: SyncManager
    private let networkMonitor: NetworkMonitor
    
    func createTasting(_ input: CreateTastingInput) async throws -> Tasting {
        // 1. Create local tasting immediately
        let localTasting = Tasting(
            id: UUID().uuidString,  // Temporary ID
            rating: input.rating,
            notes: input.notes,
            bottle: input.bottle,
            user: currentUser
        )
        localTasting.syncStatus = .pending
        
        modelContext.insert(localTasting)
        try modelContext.save()
        
        // 2. Create mutation for sync
        let request = CreateTastingRequest(from: input)
        let payload = try JSONEncoder().encode(request)
        
        let mutation = PendingMutation(
            type: .createTasting,
            entityId: localTasting.id,
            payload: payload,
            priority: .high
        )
        
        modelContext.insert(mutation)
        try modelContext.save()
        
        // 3. Attempt immediate sync if online
        if networkMonitor.isConnected {
            Task {
                await syncManager.syncPendingMutations()
            }
        }
        
        return localTasting
    }
    
    func getFeed(type: FeedType) async throws -> [Tasting] {
        // 1. Always return cached data first
        let cachedFeed = try getCachedFeed(type: type)
        
        // 2. Fetch fresh data if online
        if networkMonitor.isConnected {
            Task {
                try? await refreshFeed(type: type)
            }
        }
        
        return cachedFeed
    }
    
    private func getCachedFeed(type: FeedType) throws -> [Tasting] {
        let descriptor = FetchDescriptor<Tasting>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        
        return try modelContext.fetch(descriptor)
    }
}
```

## User Experience

### Offline Indicators
- Banner when offline
- Sync status in UI
- Queue count badge
- Last sync timestamp

### Optimistic UI
- Immediate feedback
- No loading states
- Revert on failure
- Clear error messages

### Background Sync
- Sync on app launch
- Periodic background sync
- Sync on network change
- Manual sync option

## Testing Offline Features

```swift
class OfflineTests: XCTestCase {
    func testCreateTastingOffline() async {
        // 1. Simulate offline
        networkMonitor.simulateOffline()
        
        // 2. Create tasting
        let tasting = try await repository.createTasting(input)
        
        // 3. Verify local creation
        XCTAssertEqual(tasting.syncStatus, .pending)
        XCTAssertEqual(mutationQueue.count, 1)
        
        // 4. Go online
        networkMonitor.simulateOnline()
        
        // 5. Wait for sync
        await syncManager.syncPendingMutations()
        
        // 6. Verify sync
        XCTAssertEqual(tasting.syncStatus, .synced)
        XCTAssertEqual(mutationQueue.count, 0)
    }
}
```