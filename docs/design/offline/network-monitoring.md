# Network Monitoring & Offline Support

## Overview

Peated implements a comprehensive network monitoring and offline support system using Apple's modern Network framework. The app is designed to work seamlessly both online and offline, with automatic synchronization when connectivity is restored.

## Architecture

### Network Monitor Service

We use Apple's `NWPathMonitor` for real-time network status monitoring:

```swift
@Observable
@MainActor
public class NetworkMonitor {
    public static let shared = NetworkMonitor()
    
    public private(set) var isConnected = true
    public private(set) var isExpensive = false
    public private(set) var isConstrained = false
    public private(set) var connectionType: ConnectionType = .unknown
    
    public enum ConnectionType {
        case wifi
        case cellular
        case wiredEthernet
        case unknown
    }
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.peated.networkmonitor")
    
    private init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
                self?.isExpensive = path.isExpensive
                self?.isConstrained = path.isConstrained
                
                if path.usesInterfaceType(.wifi) {
                    self?.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self?.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self?.connectionType = .wiredEthernet
                } else {
                    self?.connectionType = .unknown
                }
                
                // Notify offline queue to process pending operations
                if path.status == .satisfied {
                    await OfflineQueueManager.shared.processPendingOperations()
                }
            }
        }
        
        monitor.start(queue: queue)
    }
}
```

### Offline Queue Manager

Manages operations that need to be synced when network is available:

```swift
@Observable
@MainActor
public class OfflineQueueManager {
    public static let shared = OfflineQueueManager()
    
    public private(set) var pendingOperations: [OfflineOperation] = []
    public private(set) var isSyncing = false
    
    private let database: SQLiteDatabase
    private let maxRetries = 3
    
    private init() {
        self.database = SQLiteDatabase.shared
        loadPendingOperations()
    }
    
    public func queueOperation(_ operation: OfflineOperation) async {
        // Save to SQLite for persistence
        try? await database.saveOfflineOperation(operation)
        pendingOperations.append(operation)
        
        // Try to execute immediately if online
        if NetworkMonitor.shared.isConnected {
            await processPendingOperations()
        }
    }
    
    public func processPendingOperations() async {
        guard !isSyncing && NetworkMonitor.shared.isConnected else { return }
        
        isSyncing = true
        defer { isSyncing = false }
        
        for operation in pendingOperations {
            do {
                try await executeOperation(operation)
                
                // Remove successful operation
                pendingOperations.removeAll { $0.id == operation.id }
                try? await database.deleteOfflineOperation(operation.id)
                
            } catch {
                // Update retry count
                operation.retryCount += 1
                
                if operation.retryCount >= maxRetries {
                    // Move to failed operations
                    ToastManager.shared.showError("Failed to sync: \(operation.description)")
                    pendingOperations.removeAll { $0.id == operation.id }
                    try? await database.markOperationFailed(operation.id)
                } else {
                    // Exponential backoff
                    let delay = pow(2.0, Double(operation.retryCount))
                    try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
    }
}
```

## UI/UX Patterns

### Offline Indicator

Show network status in the UI:

```swift
struct OfflineIndicator: View {
    @State private var networkMonitor = NetworkMonitor.shared
    
    var body: some View {
        if !networkMonitor.isConnected {
            HStack(spacing: 8) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 14))
                Text("You're offline")
                    .font(.peatedCaption)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.red)
            .clipShape(Capsule())
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}
```

### Adaptive Content Loading

Adjust behavior based on connection type:

```swift
extension FeedModel {
    private func shouldLoadImages() -> Bool {
        let monitor = NetworkMonitor.shared
        
        // Always load on WiFi
        if monitor.connectionType == .wifi {
            return true
        }
        
        // Check user preferences for cellular
        if monitor.connectionType == .cellular {
            return !monitor.isExpensive && UserDefaults.standard.bool(forKey: "loadImagesOnCellular")
        }
        
        // Don't load when offline
        return false
    }
}
```

## Offline Operations

### Operation Types

```swift
public struct OfflineOperation: Codable, Identifiable {
    public let id = UUID()
    public let type: OperationType
    public let payload: Data
    public let createdAt: Date
    public var retryCount: Int = 0
    
    public enum OperationType: String, Codable {
        case createTasting
        case updateTasting
        case deleteTasting
        case toggleToast
        case addComment
        case followUser
        case unfollowUser
    }
}
```

### Creating Operations

When performing actions that require network:

```swift
public func createTasting(_ input: CreateTastingInput) async throws {
    // Create local record immediately
    let localTasting = Tasting(from: input)
    localTasting.syncStatus = .pending
    
    try await database.saveTasting(localTasting)
    
    // Queue for sync
    let operation = OfflineOperation(
        type: .createTasting,
        payload: try JSONEncoder().encode(input),
        createdAt: Date()
    )
    
    await OfflineQueueManager.shared.queueOperation(operation)
    
    // Update UI optimistically
    self.tastings.insert(localTasting, at: 0)
}
```

## Data Sync Strategy

### Conflict Resolution

We use a "server wins" strategy with optimistic updates:

1. **Optimistic Updates**: UI updates immediately
2. **Background Sync**: Operations sync when online
3. **Conflict Resolution**: Server response overwrites local state
4. **Error Recovery**: Revert optimistic updates on failure

### Sync Triggers

Synchronization happens:
- When network becomes available
- When app enters foreground
- On pull-to-refresh
- After creating/updating content
- Periodically (every 5 minutes when online)

## Implementation Guidelines

### Do's
- ✅ Always check `NetworkMonitor.shared.isConnected` before showing network-specific UI
- ✅ Queue all mutations through `OfflineQueueManager`
- ✅ Provide clear feedback about offline status
- ✅ Cache essential data for offline viewing
- ✅ Test with Network Link Conditioner
- ✅ Handle edge cases (partial connectivity, timeouts)

### Don'ts
- ❌ Block UI based on network status
- ❌ Lose user data due to network issues
- ❌ Retry infinitely without backoff
- ❌ Ignore expensive network warnings
- ❌ Assume network status won't change

## Testing

### Network Link Conditioner Setup
1. Install from Additional Tools for Xcode
2. Test scenarios:
   - 100% Loss
   - High Latency DNS
   - Very Bad Network
   - Edge Network
   - 3G Network

### Test Cases
- App launch while offline
- Network status changes during operation
- Queue persistence across app launches
- Sync conflict resolution
- Expensive network handling

## Future Enhancements

1. **Smart Sync**: Prioritize recent/important data
2. **Compression**: Reduce data usage on cellular
3. **Predictive Caching**: Pre-fetch likely content
4. **P2P Sync**: Share data between devices locally
5. **Background Sync**: iOS Background Tasks API