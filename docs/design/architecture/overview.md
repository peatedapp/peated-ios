# Architecture Overview

## System Architecture

Peated iOS follows a layered architecture optimized for mobile performance and offline functionality.

```
┌─────────────────────────────────────────┐
│         SwiftUI Views                   │
├─────────────────────────────────────────┤
│      Models (@Observable)               │
├─────────────────────────────────────────┤
│     Repository Layer                    │
├─────────────────────────────────────────┤
│  API Client  │  SQLite.swift Storage   │
├─────────────────────────────────────────┤
│      Peated API (Remote)                │
└─────────────────────────────────────────┘
```

## Core Principles

### 1. Offline-First Design
- All data is cached locally using SQLite.swift
- API calls update local cache, which updates UI
- Mutations are queued when offline and synced when connected
- Optimistic UI updates for immediate feedback

### 2. Unidirectional Data Flow
- Views hold and observe Model instances
- User actions trigger Model methods directly
- Models coordinate with repositories
- Repositories manage data sources (API + SQLite)

### 3. Dependency Injection
- Models receive repositories via initializers
- Repositories receive API client and database connection
- Testability through protocol abstractions

## Key Components

### Views (SwiftUI)
- Declarative UI components
- Hold model instances with `@State`
- Direct property binding to model properties
- Present loading, error, and empty states

### Models (@Observable)
- Manage state and business logic in one place
- Use `@Observable` macro for automatic UI updates
- Handle async operations with Swift Concurrency
- Direct property binding from views

### Repositories
- Abstract data source details from Models
- Implement caching strategies
- Handle online/offline logic
- Merge remote and local data

### API Client
- Generated from OpenAPI specification
- Type-safe request/response handling
- Automatic token injection
- Retry logic for failed requests

### SQLite.swift Storage
- Local persistence using SQLite database
- Type-safe query builder
- Manual relationship management
- Background sync support

## Data Flow Examples

### Reading Data (Feed)
1. User opens Activity tab
2. FeedView's model requests data
3. FeedModel calls FeedRepository.getFeed()
4. Repository checks SQLite cache
5. If stale, repository fetches from API
6. API response updates SQLite
7. Model properties update triggering view refresh
8. View re-renders with new data

### Writing Data (New Tasting)
1. User completes tasting creation
2. CreateTastingModel validates input
3. Model creates local Tasting in SQLite
4. Model queues API mutation
5. UI shows success with optimistic update
6. Background: API call executes
7. On success: Update local record with server ID
8. On failure: Retry queue or show error

## Navigation Architecture

### Tab-Based Navigation
- Root `TabView` with 4 main sections
- Each tab has its own navigation stack
- Floating action button overlays tab bar
- Deep linking support via URL schemes

### Modal Presentations
- Tasting creation flow (5-step process)
- Full-screen photo viewer
- User profile sheets
- Settings and preferences

## State Management

### Local State
- View-specific state using `@State`
- Temporary UI state (form inputs, toggles)

### Shared State
- User session via environment object
- Current user preferences
- Offline queue status

### Persistent State
- All user data in SQLite database
- Image cache on disk
- Authentication tokens in Keychain

## Performance Optimizations

### Lazy Loading
- Paginated feed with cursor-based loading
- Image loading on demand
- Deferred data fetching for detail views

### Caching Strategy
- SQLite.swift for structured data
- URLCache for images
- Memory cache for computed values
- Cache invalidation policies

### Background Processing
- Sync queued mutations
- Refresh stale data
- Clean expired cache
- Download images for offline viewing

## Error Handling

### Network Errors
- Automatic retry with exponential backoff
- Queue mutations when offline
- User-friendly error messages
- Pull-to-refresh recovery

### Data Validation
- Client-side validation before API calls
- Server error parsing and display
- Conflict resolution for sync issues

## Security Considerations

### Authentication
- OAuth tokens in iOS Keychain
- Automatic token refresh
- Biometric authentication option

### Data Privacy
- Local data encryption via iOS
- Secure API communication (HTTPS)
- Privacy settings for tastings
- Anonymous usage analytics

## Testing Architecture

### Unit Tests
- Models with mocked repositories
- Repository logic with mocked API/storage
- Model validation and transformations

### Integration Tests
- API client with recorded responses
- SQLite.swift operations
- Full data flow scenarios

### UI Tests
- Critical user journeys
- Accessibility verification
- Performance benchmarks