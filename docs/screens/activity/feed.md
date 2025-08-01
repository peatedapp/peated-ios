# Activity Feed Screen

## Overview

The Activity Feed is the main screen of the app, displaying a chronological feed of whisky tastings from the user's network and the global community. It follows the Untappd model with three feed types: Friends, You, and Global.

## Visual Layout

```
┌─────────────────────────────────────────┐
│   Activity              •               │ (New activity indicator)
├─────────────────────────────────────────┤
│                                         │
│  [ Friends ]  [ You ]  [ Global ]       │ (Segmented Control)
│                                         │
├─────────────────────────────────────────┤
│                                         │
│  ┌───────────────────────────────┐     │
│  │  [TastingCard Component]      │     │
│  │  John is drinking Ardbeg 10   │     │
│  │  ★★★★☆ 4.5                   │     │
│  │  🥃 23  💬 5                  │     │
│  └───────────────────────────────┘     │
│                                         │
│  ┌───────────────────────────────┐     │
│  │  [TastingCard Component]      │     │
│  │  Sarah is drinking Macallan   │     │
│  │  ★★★★★ 5.0                   │     │
│  │  🥃 45  💬 12                 │     │
│  └───────────────────────────────┘     │
│                                         │
│  [Loading more...]                      │
│                                         │
├─────────────────────────────────────────┤
│ [Feed] [Search] [Library] [Profile]     │
│              [+]                        │ (Floating Add Button)
└─────────────────────────────────────────┘
```

### Empty States

#### Friends Feed (No Following)
```
┌─────────────────────────────────────────┐
│                                         │
│              👥                         │
│                                         │
│       No Friends Activity Yet           │
│                                         │
│   Follow whisky enthusiasts to see      │
│   their tastings here                   │
│                                         │
│    ┌─────────────────────────────┐     │
│    │      Find People to Follow   │     │
│    └─────────────────────────────┘     │
│                                         │
└─────────────────────────────────────────┘
```

## Implementation

```swift
import SwiftUI

struct ActivityFeedScreen: View {
    @State private var model = ActivityFeedModel()
    @State private var selectedFeed: FeedType = .friends
    @State private var hasNewActivity = false
    
    enum FeedType: String, CaseIterable {
        case friends = "Friends"
        case you = "You"
        case global = "Global"
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Feed selector
                feedSelector
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                
                // Feed content
                feedContent
            }
            .navigationTitle("Activity")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if hasNewActivity {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 8, height: 8)
                            .offset(x: -8, y: -8)
                    }
                }
            }
            .task {
                await model.loadInitialFeed(type: selectedFeed)
            }
            .refreshable {
                await model.refreshFeed(type: selectedFeed)
            }
        }
    }
    
    // MARK: - Feed Selector
    @ViewBuilder
    private var feedSelector: some View {
        Picker("Feed Type", selection: $selectedFeed) {
            ForEach(FeedType.allCases, id: \.self) { type in
                Text(type.rawValue).tag(type)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
        .onChange(of: selectedFeed) { newValue in
            Task {
                await model.switchFeed(to: newValue)
            }
        }
    }
    
    // MARK: - Feed Content
    @ViewBuilder
    private var feedContent: some View {
        Group {
            switch model.state {
            case .loading:
                loadingView
            
            case .empty:
                emptyView
                
            case .loaded:
                feedList
                
            case .error(let message):
                errorView(message)
            }
        }
    }
    
    // MARK: - Feed List
    @ViewBuilder
    private var feedList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(model.tastings) { tasting in
                    TastingCard(
                        tasting: tasting,
                        onToast: { tasting in
                            Task {
                                await model.toggleToast(for: tasting)
                            }
                        },
                        onComment: { tasting in
                            navigateToDetail(tasting)
                        },
                        onProfile: { user in
                            navigateToProfile(user)
                        },
                        onBottle: { bottle in
                            navigateToBottle(bottle)
                        }
                    )
                    .padding(.horizontal)
                    .id(tasting.id)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .onAppear {
                        // Trigger pagination
                        if tasting == model.tastings.last {
                            Task {
                                await model.loadMore(type: selectedFeed)
                            }
                        }
                    }
                }
                
                if model.isLoadingMore {
                    ProgressView()
                        .padding()
                }
            }
            .padding(.vertical)
        }
        .scrollDismissesKeyboard(.interactively)
    }
    
    // MARK: - Loading View
    @ViewBuilder
    private var loadingView: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(0..<3) { _ in
                    TastingCardSkeleton()
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - Empty View
    @ViewBuilder
    private var emptyView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 100)
                
                Group {
                    switch selectedFeed {
                    case .friends:
                        Image(systemName: "person.2")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("No Friends Activity Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Follow whisky enthusiasts to see\ntheir tastings here")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        NavigationLink(destination: SearchScreen(initialTab: .people)) {
                            Text("Find People to Follow")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.accentColor)
                                .cornerRadius(20)
                        }
                        
                    case .you:
                        Image(systemName: "plus.square.dashed")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("No Tastings Yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Start your whisky journey\nby adding your first tasting")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button(action: { showCreateTasting() }) {
                            Text("Add Your First Tasting")
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.accentColor)
                                .cornerRadius(20)
                        }
                        
                    case .global:
                        Image(systemName: "globe")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("No Recent Activity")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Be the first to share a tasting")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Error View
    @ViewBuilder
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Oops!")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                Task {
                    await model.retry(type: selectedFeed)
                }
            }) {
                Text("Try Again")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .cornerRadius(20)
            }
        }
        .padding()
    }
    
    // MARK: - Navigation
    private func navigateToDetail(_ tasting: Tasting) {
        // Navigate to tasting detail
    }
    
    private func navigateToProfile(_ user: User) {
        // Navigate to user profile
    }
    
    private func navigateToBottle(_ bottle: Bottle) {
        // Navigate to bottle detail
    }
    
    private func showCreateTasting() {
        // Show create tasting flow
    }
}

// MARK: - Model
@Observable
class ActivityFeedModel {
    var tastings: [Tasting] = []
    var state: FeedState = .loading
    var isLoadingMore = false
    
    private let feedRepository: FeedRepository
    private var currentFeedType: ActivityFeedScreen.FeedType = .friends
    private var cursor: String?
    private var hasMore = true
    
    enum FeedState {
        case loading
        case loaded
        case empty
        case error(String)
    }
    
    init(feedRepository: FeedRepository = FeedRepositoryImpl()) {
        self.feedRepository = feedRepository
    }
    
    func loadInitialFeed(type: ActivityFeedScreen.FeedType) async {
        state = .loading
        currentFeedType = type
        cursor = nil
        hasMore = true
        
        do {
            let feedPage = try await feedRepository.getFeed(
                type: mapFeedType(type),
                cursor: nil
            )
            
            tastings = feedPage.tastings
            cursor = feedPage.cursor
            hasMore = feedPage.hasMore
            
            state = tastings.isEmpty ? .empty : .loaded
        } catch {
            state = .error(error.localizedDescription)
        }
    }
    
    func refreshFeed(type: ActivityFeedScreen.FeedType) async {
        // Don't show loading state on refresh
        do {
            let feedPage = try await feedRepository.getFeed(
                type: mapFeedType(type),
                cursor: nil
            )
            
            // Prepend new items
            let newTastings = feedPage.tastings.filter { newTasting in
                !tastings.contains { $0.id == newTasting.id }
            }
            
            withAnimation {
                tastings = newTastings + tastings
            }
        } catch {
            // Silent failure on refresh
        }
    }
    
    func loadMore(type: ActivityFeedScreen.FeedType) async {
        guard hasMore && !isLoadingMore else { return }
        
        isLoadingMore = true
        
        do {
            let feedPage = try await feedRepository.getFeed(
                type: mapFeedType(type),
                cursor: cursor
            )
            
            withAnimation {
                tastings.append(contentsOf: feedPage.tastings)
            }
            
            cursor = feedPage.cursor
            hasMore = feedPage.hasMore
        } catch {
            // Handle pagination error
        }
        
        isLoadingMore = false
    }
    
    func switchFeed(to type: ActivityFeedScreen.FeedType) async {
        await loadInitialFeed(type: type)
    }
    
    func retry(type: ActivityFeedScreen.FeedType) async {
        await loadInitialFeed(type: type)
    }
    
    func toggleToast(for tasting: Tasting) async {
        // Optimistic update
        if let index = tastings.firstIndex(where: { $0.id == tasting.id }) {
            withAnimation(.spring(response: 0.3)) {
                tastings[index].hasToasted.toggle()
                tastings[index].toastCount += tastings[index].hasToasted ? 1 : -1
            }
        }
        
        // API call
        do {
            if tasting.hasToasted {
                try await feedRepository.removeToast(tastingId: tasting.id)
            } else {
                try await feedRepository.addToast(tastingId: tasting.id)
            }
        } catch {
            // Revert on error
            if let index = tastings.firstIndex(where: { $0.id == tasting.id }) {
                withAnimation {
                    tastings[index].hasToasted.toggle()
                    tastings[index].toastCount += tastings[index].hasToasted ? 1 : -1
                }
            }
        }
    }
    
    private func mapFeedType(_ type: ActivityFeedScreen.FeedType) -> FeedType {
        switch type {
        case .friends: return .following
        case .you: return .self
        case .global: return .global
        }
    }
}

// MARK: - Skeleton View
struct TastingCardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 44, height: 44)
                
                VStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 150, height: 16)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 100, height: 14)
                }
                
                Spacer()
            }
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 200, height: 20)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 60)
            }
            
            // Footer
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 16)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 16)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .redacted(reason: .placeholder)
        .shimmering()
    }
}
```

## Navigation

### Entry Points
- Tab bar selection (default tab)
- App launch when authenticated
- Push notification tap

### Exit Points
- Tasting detail (tap card)
- User profile (tap avatar/username)
- Bottle detail (tap bottle)
- Create tasting (floating button)
- Search (tab navigation)

## Data Flow

### Feed Types
1. **Friends**: Tastings from followed users
2. **You**: Current user's tasting history  
3. **Global**: All public tastings

### Pagination
- Cursor-based pagination
- 20 items per page
- Preload when reaching last 3 items
- Show loading indicator at bottom

### Real-time Updates
- Pull-to-refresh for new content
- New activity indicator in nav bar
- Cache feed data for offline viewing
- Background refresh every 5 minutes

## State Management

### Feed State
- Loading (initial)
- Loaded (with data)
- Empty (no data)
- Error (network/API failure)
- Refreshing (pull-to-refresh)
- Loading more (pagination)

### Optimistic Updates
- Toast count updates immediately
- Revert on API failure
- Show inline error messages

## Performance

### Optimization Strategies
1. **Lazy Loading**: Use LazyVStack for efficient scrolling
2. **Image Caching**: Cache bottle and user images
3. **Prefetching**: Load next page before reaching end
4. **Skeleton Loading**: Show placeholders during load
5. **Incremental Updates**: Only update changed items

### Memory Management
- Limit cached tastings to 100
- Clear old images from cache
- Cancel image loads on scroll

## Accessibility

- VoiceOver announces feed changes
- Pull-to-refresh is accessible
- Empty states have clear CTAs
- Loading states announced
- Semantic navigation

## Error Handling

### Network Errors
- Show retry button
- Cache last successful load
- Work offline with cached data

### Empty States
- Different message per feed type
- Action buttons to resolve
- Helpful illustrations

## Testing Scenarios

1. Initial load for each feed type
2. Pull-to-refresh behavior
3. Pagination edge cases
4. Empty state interactions
5. Error state recovery
6. Rapid feed switching
7. Toast interaction
8. Offline mode