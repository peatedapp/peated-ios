# Search Screen

## Overview

The Search screen provides unified search functionality across bottles, entities (brands, distillers, bottlers), and users. Results are automatically optimized based on the search query, with mixed-format results displayed in a single list.

## Visual Layout

```
┌─────────────────────────────────────────┐
│   Search                                │
├─────────────────────────────────────────┤
│  ┌─────────────────────────────────┐   │
│  │ 🔍 Search bottles, brands, users │   │
│  └─────────────────────────────────┘   │
│                                         │
│  Recent Searches                        │
│  ┌─────────────────────────────────┐   │
│  │ Ardbeg                        ✕ │   │
│  │ @whiskyexpert                 ✕ │   │
│  │ Macallan 18                   ✕ │   │
│  └─────────────────────────────────┘   │
│                                         │
│  Popular Bottles                        │
│  ┌─────────────────────────────────┐   │
│  │ [Bottle] Glenfiddich 12        │   │
│  │         Single Malt • 40%       │   │
│  │         ★★★★☆ 4.2              │   │
│  └─────────────────────────────────┘   │
│                                         │
└─────────────────────────────────────────┘
```

### Active Search Results
```
┌─────────────────────────────────────────┐
│   Search                          Cancel│
├─────────────────────────────────────────┤
│  ┌─────────────────────────────────┐   │
│  │ 🔍 Lagavulin                    │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ BOTTLES                         │   │
│  │ [Bottle] Lagavulin 16          │   │
│  │         Islay • Single Malt     │   │
│  │         ★★★★☆ 4.5 (823)        │   │
│  │                                 │   │
│  │ [Bottle] Lagavulin 8           │   │
│  │         Islay • Single Malt     │   │
│  │         ★★★★☆ 4.3 (412)        │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ DISTILLERIES                    │   │
│  │ [Building] Lagavulin Distillery │   │
│  │           Islay, Scotland       │   │
│  │           Est. 1816             │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ USERS                           │   │
│  │ [Avatar] LagavulinLover         │   │
│  │         523 tastings • 89 unique│   │
│  │         Following               │   │
│  └─────────────────────────────────┘   │
│                                         │
└─────────────────────────────────────────┘
```

## Implementation

```swift
import SwiftUI

struct SearchScreen: View {
    @State private var model = SearchModel()
    @State private var searchText = ""
    @State private var isSearching = false
    @FocusState private var isSearchFieldFocused: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Custom search bar
                searchBar
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                
                // Content
                Group {
                    if searchText.isEmpty {
                        defaultView
                    } else {
                        searchResultsView
                    }
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarHidden(isSearching)
            .animation(.easeInOut(duration: 0.2), value: isSearching)
        }
    }
    
    // MARK: - Search Bar
    @ViewBuilder
    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search bottles, brands, users", text: $searchText)
                    .textFieldStyle(.plain)
                    .focused($isSearchFieldFocused)
                    .onSubmit {
                        model.addToRecentSearches(searchText)
                    }
                    .onChange(of: searchText) { newValue in
                        model.search(query: newValue)
                    }
                
                if !searchText.isEmpty {
                    Button(action: { 
                        searchText = ""
                        model.clearResults()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10)
            
            if isSearching {
                Button("Cancel") {
                    searchText = ""
                    isSearchFieldFocused = false
                    isSearching = false
                    model.clearResults()
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .onChange(of: isSearchFieldFocused) { focused in
            withAnimation {
                isSearching = focused
            }
        }
    }
    
    // MARK: - Default View
    @ViewBuilder
    private var defaultView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Recent searches
                if !model.recentSearches.isEmpty {
                    recentSearchesSection
                }
                
                // Popular bottles
                popularBottlesSection
                
                // Top rated
                topRatedSection
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - Recent Searches
    @ViewBuilder
    private var recentSearchesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Searches")
                    .font(.headline)
                
                Spacer()
                
                Button("Clear") {
                    model.clearRecentSearches()
                }
                .font(.caption)
                .foregroundColor(.accentColor)
            }
            .padding(.horizontal)
            
            VStack(spacing: 0) {
                ForEach(model.recentSearches, id: \.self) { search in
                    Button(action: {
                        searchText = search
                        model.search(query: search)
                    }) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(search)
                                .font(.body)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button(action: {
                                model.removeRecentSearch(search)
                            }) {
                                Image(systemName: "xmark")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                    
                    if search != model.recentSearches.last {
                        Divider()
                            .padding(.leading, 44)
                    }
                }
            }
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    // MARK: - Search Results View
    @ViewBuilder
    private var searchResultsView: some View {
        Group {
            switch model.searchState {
            case .idle:
                EmptyView()
                
            case .searching:
                loadingView
                
            case .results(let results):
                if results.isEmpty {
                    noResultsView
                } else {
                    resultsListView(results)
                }
                
            case .error(let message):
                errorView(message)
            }
        }
    }
    
    // MARK: - Results List
    @ViewBuilder
    private func resultsListView(_ results: [SearchResult]) -> some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Group results by type
                let groupedResults = Dictionary(grouping: results) { $0.type }
                
                ForEach(SearchResultType.allCases, id: \.self) { type in
                    if let typeResults = groupedResults[type], !typeResults.isEmpty {
                        resultSection(type: type, results: typeResults)
                    }
                }
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - Result Section
    @ViewBuilder
    private func resultSection(type: SearchResultType, results: [SearchResult]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(type.sectionTitle)
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                ForEach(results) { result in
                    Button(action: {
                        handleResultTap(result)
                    }) {
                        searchResultRow(result)
                    }
                    .buttonStyle(.plain)
                    
                    if result != results.last {
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    // MARK: - Search Result Row
    @ViewBuilder
    private func searchResultRow(_ result: SearchResult) -> some View {
        HStack(spacing: 12) {
            // Icon/Image
            Group {
                switch result.type {
                case .bottle:
                    if let imageUrl = result.imageUrl {
                        AsyncImage(url: URL(string: imageUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Image(systemName: "photo")
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Image("BottlePlaceholder")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                    
                case .brand, .distillery, .bottler:
                    Image(systemName: result.type.iconName)
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .frame(width: 44, height: 44)
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(8)
                    
                case .user:
                    if let avatarUrl = result.imageUrl {
                        AsyncImage(url: URL(string: avatarUrl)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                    }
                }
            }
            .frame(width: 44, height: 44)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(result.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if let subtitle = result.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    .lineLimit(1)
                }
                
                if result.type == .bottle, let rating = result.rating {
                    HStack(spacing: 4) {
                        RatingView(rating: rating, size: 12)
                        Text(String(format: "%.1f", rating))
                            .font(.caption)
                            .foregroundColor(.primary)
                        if let ratingCount = result.ratingCount {
                            Text("(\(ratingCount))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            // Accessory
            if result.type == .user {
                if let isFollowing = result.isFollowing {
                    if isFollowing {
                        Text("Following")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Button("Follow") {
                            // Handle follow
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.tertiary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
    
    // MARK: - Loading View
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 16) {
            ForEach(0..<5) { _ in
                HStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 44, height: 44)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 150, height: 16)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 100, height: 12)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal)
                .redacted(reason: .placeholder)
                .shimmering()
            }
        }
        .padding(.vertical)
    }
    
    // MARK: - No Results View
    @ViewBuilder
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            Text("No results for \"\(searchText)\"")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text("Try searching for something else")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Actions
    private func handleResultTap(_ result: SearchResult) {
        model.addToRecentSearches(result.name)
        
        switch result.type {
        case .bottle:
            // Navigate to bottle detail
            break
        case .brand, .distillery, .bottler:
            // Navigate to entity page
            break
        case .user:
            // Navigate to user profile
            break
        }
    }
}

// MARK: - Search Result Models
enum SearchResultType: String, CaseIterable {
    case bottle
    case brand
    case distillery
    case bottler
    case user
    
    var sectionTitle: String {
        switch self {
        case .bottle: return "BOTTLES"
        case .brand: return "BRANDS"
        case .distillery: return "DISTILLERIES"
        case .bottler: return "BOTTLERS"
        case .user: return "USERS"
        }
    }
    
    var iconName: String {
        switch self {
        case .bottle: return "wineglass"
        case .brand: return "tag"
        case .distillery: return "building.2"
        case .bottler: return "building"
        case .user: return "person.circle"
        }
    }
}

struct SearchResult: Identifiable, Equatable {
    let id: String
    let type: SearchResultType
    let name: String
    let subtitle: String?
    let imageUrl: String?
    let rating: Double?
    let ratingCount: Int?
    let isFollowing: Bool?
}

// MARK: - Model
@Observable
class SearchModel {
    var searchState: SearchState = .idle
    var recentSearches: [String] = []
    var popularBottles: [Bottle] = []
    var topRatedBottles: [Bottle] = []
    
    private let searchRepository: SearchRepository
    private var searchTask: Task<Void, Never>?
    
    enum SearchState {
        case idle
        case searching
        case results([SearchResult])
        case error(String)
    }
    
    init(searchRepository: SearchRepository = SearchRepositoryImpl()) {
        self.searchRepository = searchRepository
        loadRecentSearches()
        loadPopularContent()
    }
    
    func search(query: String) {
        // Cancel previous search
        searchTask?.cancel()
        
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchState = .idle
            return
        }
        
        searchState = .searching
        
        searchTask = Task {
            do {
                // Debounce
                try await Task.sleep(nanoseconds: 300_000_000) // 300ms
                
                if !Task.isCancelled {
                    let results = try await searchRepository.search(query: query)
                    
                    if !Task.isCancelled {
                        searchState = .results(results)
                    }
                }
            } catch {
                if !Task.isCancelled {
                    searchState = .error(error.localizedDescription)
                }
            }
        }
    }
    
    func clearResults() {
        searchTask?.cancel()
        searchState = .idle
    }
    
    // MARK: - Recent Searches
    func addToRecentSearches(_ query: String) {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else { return }
        
        // Remove if already exists
        recentSearches.removeAll { $0 == trimmedQuery }
        
        // Add to beginning
        recentSearches.insert(trimmedQuery, at: 0)
        
        // Keep only last 10
        if recentSearches.count > 10 {
            recentSearches = Array(recentSearches.prefix(10))
        }
        
        saveRecentSearches()
    }
    
    func removeRecentSearch(_ query: String) {
        recentSearches.removeAll { $0 == query }
        saveRecentSearches()
    }
    
    func clearRecentSearches() {
        recentSearches = []
        saveRecentSearches()
    }
    
    private func loadRecentSearches() {
        if let searches = UserDefaults.standard.stringArray(forKey: "recentSearches") {
            recentSearches = searches
        }
    }
    
    private func saveRecentSearches() {
        UserDefaults.standard.set(recentSearches, forKey: "recentSearches")
    }
    
    // MARK: - Popular Content
    private func loadPopularContent() {
        Task {
            do {
                popularBottles = try await searchRepository.getPopularBottles()
                topRatedBottles = try await searchRepository.getTopRatedBottles()
            } catch {
                // Handle error
            }
        }
    }
}
```

## Navigation

### Entry Points
- Tab bar navigation
- "Find People to Follow" from empty feed
- Quick actions from other screens

### Exit Points
- Bottle detail
- User profile  
- Entity pages (brand/distillery/bottler)
- Back to previous tab

## Search Behavior

### Query Processing
- Debounced input (300ms)
- Minimum 1 character
- Case-insensitive
- Partial matching

### Result Ranking
- API optimizes result order
- Bottles prioritized for bottle-like queries
- Users prioritized for @username queries
- Exact matches ranked higher

### Result Types
1. **Bottles**: Name, category, ABV, rating
2. **Brands**: Name, country/region
3. **Distilleries**: Name, location, established
4. **Bottlers**: Name, type
5. **Users**: Username, display name, stats

## Data Management

### Recent Searches
- Store last 10 searches locally
- UserDefaults persistence
- Clear individual or all
- Tap to repeat search

### Popular Content
- Load on screen init
- Cache for session
- Refresh on pull-to-refresh

## Performance

### Optimizations
- Debounced search input
- Cancel in-flight requests
- Lazy loading results
- Image caching
- Efficient result grouping

### Memory Management
- Limit result count
- Clear results on cancel
- Reuse view components

## Accessibility

- Search field announces state
- Results grouped by type
- Clear actions for recent searches
- VoiceOver optimized

## Error States

- Network failure
- No results found
- Rate limiting
- Server errors

## Testing Scenarios

1. Various search queries
2. Rapid typing/deletion
3. Network interruption
4. Empty results
5. Recent search management
6. Deep linking to search