# Network Monitoring & Offline Support Implementation Plan

## Phase 1: Core Infrastructure (Week 1)

### 1.1 Network Monitor Service
**Priority: High**
**Effort: 2 days**

Create `NetworkMonitor.swift` in PeatedCore:
- [ ] Implement NWPathMonitor wrapper
- [ ] Add @Observable properties for network state
- [ ] Handle connection type detection (WiFi/Cellular)
- [ ] Detect expensive and constrained connections
- [ ] Add singleton instance for app-wide access

### 1.2 Offline Queue Infrastructure
**Priority: High**
**Effort: 3 days**

Create offline queue system:
- [ ] Design `OfflineOperation` model
- [ ] Implement `OfflineQueueManager` service
- [ ] Add SQLite persistence for queue
- [ ] Implement retry logic with exponential backoff
- [ ] Handle operation expiration (>7 days old)

### 1.3 SQLite Schema Updates
**Priority: High**
**Effort: 1 day**

Update database schema:
```sql
CREATE TABLE offline_operations (
    id TEXT PRIMARY KEY,
    type TEXT NOT NULL,
    payload BLOB NOT NULL,
    created_at TIMESTAMP NOT NULL,
    retry_count INTEGER DEFAULT 0,
    last_attempt_at TIMESTAMP,
    status TEXT DEFAULT 'pending'
);

ALTER TABLE tastings ADD COLUMN sync_status TEXT DEFAULT 'synced';
ALTER TABLE tastings ADD COLUMN local_id TEXT;
```

## Phase 2: UI Components (Week 2)

### 2.1 Offline Indicator
**Priority: Medium**
**Effort: 1 day**

Create UI components:
- [ ] `OfflineIndicator.swift` - banner component
- [ ] Add to `AppView` below navigation
- [ ] Animate appearance/disappearance
- [ ] Show different messages for different states

### 2.2 Sync Status Indicators
**Priority: Medium**
**Effort: 2 days**

Add sync feedback:
- [ ] Pending sync badge on tastings
- [ ] Sync progress indicator in profile
- [ ] Failed sync error states
- [ ] Pull-to-refresh integration

### 2.3 Adaptive Content Loading
**Priority: Low**
**Effort: 1 day**

Optimize for network conditions:
- [ ] Disable image loading when offline
- [ ] Reduce image quality on cellular
- [ ] Defer non-critical requests
- [ ] Add user preferences for cellular data

## Phase 3: Feature Integration (Week 3)

### 3.1 Tasting Creation
**Priority: High**
**Effort: 2 days**

Update tasting flow:
- [ ] Generate local IDs for offline creation
- [ ] Queue upload when offline
- [ ] Handle photo uploads separately
- [ ] Update local ID with server ID after sync

### 3.2 Social Actions
**Priority: Medium**
**Effort: 2 days**

Queue social interactions:
- [ ] Toast/untoast operations
- [ ] Follow/unfollow users
- [ ] Comment creation
- [ ] Profile updates

### 3.3 Feed Synchronization
**Priority: High**
**Effort: 2 days**

Smart feed caching:
- [ ] Cache feed data with timestamps
- [ ] Merge offline changes with server data
- [ ] Handle pagination with offline data
- [ ] Conflict resolution for modified items

## Phase 4: Advanced Features (Week 4)

### 4.1 Background Sync
**Priority: Low**
**Effort: 3 days**

iOS Background Tasks:
- [ ] Register background task identifiers
- [ ] Implement BGProcessingTask for sync
- [ ] Handle app refresh tasks
- [ ] Energy-efficient scheduling

### 4.2 Data Usage Optimization
**Priority: Low**
**Effort: 2 days**

Reduce cellular data:
- [ ] Implement request compression
- [ ] Delta sync for feed updates
- [ ] Progressive image loading
- [ ] Prefetch on WiFi only

## Implementation Order

1. **Week 1**: Network Monitor + Basic Queue
   - Get core infrastructure working
   - Test with simple operations

2. **Week 2**: UI Feedback
   - Users can see offline status
   - Visual feedback for sync

3. **Week 3**: Feature Integration
   - Offline creation works
   - Social actions queue properly

4. **Week 4**: Optimization
   - Background sync
   - Data usage reduction

## Testing Strategy

### Unit Tests
```swift
func testNetworkMonitorStatusChanges() async {
    let monitor = NetworkMonitor()
    // Simulate network changes
    // Verify state updates
}

func testOfflineQueuePersistence() async {
    let queue = OfflineQueueManager()
    // Add operations
    // Restart app
    // Verify operations persist
}
```

### Integration Tests
- Test with Network Link Conditioner
- Airplane mode transitions
- Background/foreground sync
- Conflict resolution scenarios

### UI Tests
- Offline indicator appearance
- Sync status updates
- Error state handling

## Migration Path

1. **Deploy Phase 1** without UI changes
2. **Monitor** queue behavior in production
3. **Add UI** indicators gradually
4. **Enable** offline creation last

## Success Metrics

- Queue processing success rate > 95%
- Sync conflicts < 1%
- User data loss = 0
- Offline usage increase by 20%
- Reduced API errors by 50%

## Risk Mitigation

1. **Data Loss**: Triple redundancy (memory, SQLite, iCloud backup)
2. **Sync Loops**: Operation deduplication and timeouts
3. **Battery Drain**: Intelligent retry backoff
4. **Storage Growth**: Automatic cleanup after 7 days
5. **Complexity**: Feature flags for gradual rollout