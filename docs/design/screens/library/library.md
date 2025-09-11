# Library Screen

## Overview

The Library screen is the user's personal whisky collection hub, featuring lists for organizing bottles, comprehensive statistics, and quick access to their whisky journey. It supports custom lists alongside default collections like favorites, owned bottles, and wishlist.

## Visual Layout

```
┌─────────────────────────────────────────┐
│  Library                                │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ 📊 Your Whisky Journey          │   │
│  │                                 │   │
│  │  234        89        4.2       │   │
│  │  Tastings   Unique    Avg Rating│   │
│  │                                 │   │
│  │  [View Detailed Stats →]        │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ 🔍 Search your library...       │   │
│  └─────────────────────────────────┘   │
│                                         │
│  My Lists                               │
│  ┌─────────────────────────────────┐   │
│  │ ⭐ Favorites              (23)  │   │
│  │ 📚 My Collection          (45)  │   │
│  │ 🎯 Wishlist              (12)  │   │
│  │ 🏆 Top Rated             (15)  │   │
│  │ + Create New List              │   │
│  └─────────────────────────────────┘   │
│                                         │
│  Recent Tastings                        │
│  ┌─────────────────────────────────┐   │
│  │ [Bottle] Ardbeg 10       ★★★★☆ │   │
│  │         3 days ago             │   │
│  │ [Bottle] Macallan 18     ★★★★★ │   │
│  │         1 week ago             │   │
│  └─────────────────────────────────┘   │
│                                         │
├─────────────────────────────────────────┤
│ [Feed] [Search] [Library] [Profile]     │
└─────────────────────────────────────────┘
```

### List Detail View
```
┌─────────────────────────────────────────┐
│  ← Library         Favorites      •••   │
├─────────────────────────────────────────┤
│                                         │
│  23 bottles                  Sort: A-Z ▼│
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ 🔍 Search favorites...          │   │
│  └─────────────────────────────────┘   │
│                                         │
│  Filter: All ▼  View: [Grid] List      │
│                                         │
│  ┌───────┬───────┬───────┐            │
│  │       │       │       │            │
│  │[Bottle]│[Bottle]│[Bottle]│           │
│  │  4.5   │  4.8   │  4.3   │          │
│  │Ardbeg │Lagavul│Macall │            │
│  └───────┴───────┴───────┘            │
│                                         │
│  ┌───────┬───────┬───────┐            │
│  │       │       │       │            │
│  │[Bottle]│[Bottle]│[Bottle]│           │
│  │  4.7   │  4.2   │  4.9   │          │
│  └───────┴───────┴───────┘            │
│                                         │
└─────────────────────────────────────────┘
```

## Implementation

```swift
import SwiftUI

struct LibraryScreen: View {
    @StateObject private var viewModel = LibraryViewModel()
    @State private var searchText = ""
    @State private var showingCreateList = false
    @State private var selectedList: WhiskyList?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Stats card
                    statsCard
                        .padding(.horizontal)
                    
                    // Search bar
                    searchBar
                        .padding(.horizontal)
                    
                    // Lists section
                    listsSection
                    
                    // Recent tastings
                    recentTastingsSection
                }
                .padding(.vertical)
            }
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingCreateList = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateList) {
                CreateListView()
            }
            .sheet(item: $selectedList) { list in
                NavigationView {
                    ListDetailView(list: list)
                }
            }
            .task {
                await viewModel.loadLibrary()
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
    }
    
    // MARK: - Stats Card
    @ViewBuilder
    private var statsCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .font(.title3)
                    .foregroundColor(.accentColor)
                
                Text("Your Whisky Journey")
                    .font(.headline)
                
                Spacer()
            }
            
            HStack(spacing: 0) {
                statItem(
                    value: "\(viewModel.stats.totalTastings)",
                    label: "Tastings",
                    icon: "checkmark.circle"
                )
                
                Divider()
                    .frame(height: 40)
                    .padding(.horizontal)
                
                statItem(
                    value: "\(viewModel.stats.uniqueBottles)",
                    label: "Unique",
                    icon: "square.grid.2x2"
                )
                
                Divider()
                    .frame(height: 40)
                    .padding(.horizontal)
                
                statItem(
                    value: String(format: "%.1f", viewModel.stats.averageRating),
                    label: "Avg Rating",
                    icon: "star.fill"
                )
            }
            
            NavigationLink(destination: DetailedStatsView()) {
                HStack {
                    Text("View Detailed Stats")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    
                    Image(systemName: "arrow.right")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    @ViewBuilder
    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text(label)
                    .font(.caption)
            }
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Search Bar
    @ViewBuilder
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search your library...", text: $searchText)
                .textFieldStyle(.plain)
                .onChange(of: searchText) { _ in
                    viewModel.searchLibrary(searchText)
                }
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
    
    // MARK: - Lists Section
    @ViewBuilder
    private var listsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("My Lists")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                // Default lists
                ForEach(viewModel.defaultLists) { list in
                    ListRow(
                        list: list,
                        onTap: { selectedList = list }
                    )
                    
                    if list != viewModel.defaultLists.last && list != viewModel.customLists.first {
                        Divider()
                            .padding(.leading, 56)
                    }
                }
                
                // Custom lists
                ForEach(viewModel.customLists) { list in
                    Divider()
                        .padding(.leading, 56)
                    
                    ListRow(
                        list: list,
                        onTap: { selectedList = list },
                        isCustom: true
                    )
                }
                
                // Create new list
                Divider()
                    .padding(.leading, 56)
                
                Button(action: { showingCreateList = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.accentColor)
                        
                        Text("Create New List")
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    // MARK: - Recent Tastings Section
    @ViewBuilder
    private var recentTastingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Tastings")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink(destination: AllTastingsView()) {
                    Text("See all")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal)
            
            if viewModel.recentTastings.isEmpty {
                EmptyStateCard(
                    icon: "clock",
                    message: "No tastings yet",
                    action: "Add your first tasting",
                    onAction: {
                        // Show create tasting
                    }
                )
                .padding(.horizontal)
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.recentTastings.prefix(5)) { tasting in
                        RecentTastingRow(
                            tasting: tasting,
                            onTap: {
                                // Navigate to tasting detail
                            }
                        )
                        
                        if tasting != viewModel.recentTastings.prefix(5).last {
                            Divider()
                                .padding(.leading, 72)
                        }
                    }
                }
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - List Row
struct ListRow: View {
    let list: WhiskyList
    let onTap: () -> Void
    var isCustom: Bool = false
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: list.iconName)
                    .font(.title3)
                    .foregroundColor(isCustom ? .secondary : list.iconColor)
                    .frame(width: 32)
                
                VStack(alignment: .leading) {
                    Text(list.name)
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    if let description = list.description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                Text("(\(list.bottleCount))")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.tertiary)
            }
            .padding()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Recent Tasting Row
struct RecentTastingRow: View {
    let tasting: Tasting
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Bottle image
                AsyncImage(url: URL(string: tasting.bottle?.imageUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Image("BottlePlaceholder")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                .frame(width: 40, height: 56)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(tasting.bottle?.name ?? "")
                        .font(.body)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        RatingView(rating: tasting.rating, size: 12)
                        
                        Text("•")
                            .foregroundColor(.secondary)
                        
                        Text(tasting.createdAt.relativeTime)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.tertiary)
            }
            .padding()
        }
        .buttonStyle(.plain)
    }
}

// MARK: - List Detail View
struct ListDetailView: View {
    let list: WhiskyList
    @StateObject private var viewModel: ListDetailViewModel
    @State private var searchText = ""
    @State private var sortOption: SortOption = .dateAdded
    @State private var filterOption: FilterOption = .all
    @State private var viewMode: ViewMode = .grid
    @State private var showingSortPicker = false
    @State private var showingFilterPicker = false
    @Environment(\.dismiss) private var dismiss
    
    enum SortOption: String, CaseIterable {
        case dateAdded = "Date Added"
        case name = "Name"
        case rating = "Rating"
        case abv = "ABV"
        case price = "Price"
        
        var icon: String {
            switch self {
            case .dateAdded: return "calendar"
            case .name: return "textformat"
            case .rating: return "star"
            case .abv: return "percent"
            case .price: return "dollarsign"
            }
        }
    }
    
    enum FilterOption: String, CaseIterable {
        case all = "All"
        case scotch = "Scotch"
        case bourbon = "Bourbon"
        case rye = "Rye"
        case irish = "Irish"
        case japanese = "Japanese"
        case other = "Other"
    }
    
    enum ViewMode {
        case grid
        case list
    }
    
    init(list: WhiskyList) {
        self.list = list
        self._viewModel = StateObject(wrappedValue: ListDetailViewModel(list: list))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header info
            HStack {
                Text("\(viewModel.bottles.count) bottles")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Menu {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button(action: { sortOption = option }) {
                            Label(option.rawValue, systemImage: option.icon)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("Sort: \(sortOption.rawValue)")
                            .font(.subheadline)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .foregroundColor(.accentColor)
                }
            }
            .padding()
            
            // Search and filters
            VStack(spacing: 12) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search \(list.name.lowercased())...", text: $searchText)
                        .textFieldStyle(.plain)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
                
                // Filter and view options
                HStack {
                    Menu {
                        ForEach(FilterOption.allCases, id: \.self) { option in
                            Button(action: { filterOption = option }) {
                                Text(option.rawValue)
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text("Filter: \(filterOption.rawValue)")
                                .font(.caption)
                            Image(systemName: "chevron.down")
                                .font(.caption2)
                        }
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(.tertiarySystemBackground))
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    // View mode toggle
                    HStack(spacing: 8) {
                        Button(action: { viewMode = .grid }) {
                            Image(systemName: "square.grid.2x2")
                                .foregroundColor(viewMode == .grid ? .accentColor : .secondary)
                        }
                        
                        Button(action: { viewMode = .list }) {
                            Image(systemName: "list.bullet")
                                .foregroundColor(viewMode == .list ? .accentColor : .secondary)
                        }
                    }
                    .padding(4)
                    .background(Color(.tertiarySystemBackground))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
            
            // Content
            ScrollView {
                Group {
                    if viewMode == .grid {
                        gridView
                    } else {
                        listView
                    }
                }
                .padding()
            }
        }
        .navigationTitle(list.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    if list.isCustom {
                        Button(action: { /* Edit list */ }) {
                            Label("Edit List", systemImage: "pencil")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive, action: { /* Delete list */ }) {
                            Label("Delete List", systemImage: "trash")
                        }
                    }
                    
                    Button(action: { /* Share list */ }) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .task {
            await viewModel.loadBottles()
        }
    }
    
    // MARK: - Grid View
    @ViewBuilder
    private var gridView: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            ForEach(filteredBottles) { bottle in
                BottleGridItem(
                    bottle: bottle,
                    userRating: getUserRating(for: bottle),
                    onTap: {
                        // Navigate to bottle detail
                    }
                )
            }
        }
    }
    
    // MARK: - List View
    @ViewBuilder
    private var listView: some View {
        LazyVStack(spacing: 0) {
            ForEach(filteredBottles) { bottle in
                BottleListRow(
                    bottle: bottle,
                    userRating: getUserRating(for: bottle),
                    onTap: {
                        // Navigate to bottle detail
                    }
                )
                
                if bottle != filteredBottles.last {
                    Divider()
                        .padding(.leading, 72)
                }
            }
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private var filteredBottles: [Bottle] {
        viewModel.bottles
            .filter { bottle in
                if !searchText.isEmpty {
                    return bottle.name.localizedCaseInsensitiveContains(searchText)
                }
                return true
            }
            .filter { bottle in
                switch filterOption {
                case .all:
                    return true
                default:
                    return bottle.category?.rawValue.lowercased() == filterOption.rawValue.lowercased()
                }
            }
            .sorted { lhs, rhs in
                switch sortOption {
                case .dateAdded:
                    return true // Sort by date added to list
                case .name:
                    return lhs.name < rhs.name
                case .rating:
                    return (getUserRating(for: lhs) ?? 0) > (getUserRating(for: rhs) ?? 0)
                case .abv:
                    return (lhs.abv ?? 0) > (rhs.abv ?? 0)
                case .price:
                    return true // Sort by price if available
                }
            }
    }
    
    private func getUserRating(for bottle: Bottle) -> Double? {
        // Get user's rating for this bottle
        bottle.userRating
    }
}

// MARK: - Bottle Grid Item
struct BottleGridItem: View {
    let bottle: Bottle
    let userRating: Double?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Bottle image
                AsyncImage(url: URL(string: bottle.imageUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Image("BottlePlaceholder")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                .frame(height: 100)
                
                VStack(spacing: 4) {
                    Text(bottle.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    
                    if let rating = userRating {
                        HStack(spacing: 2) {
                            RatingView(rating: rating, size: 10)
                            Text(String(format: "%.1f", rating))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - View Model
@MainActor
class LibraryViewModel: ObservableObject {
    @Published var stats = LibraryStats()
    @Published var defaultLists: [WhiskyList] = []
    @Published var customLists: [WhiskyList] = []
    @Published var recentTastings: [Tasting] = []
    @Published var isLoading = false
    
    struct LibraryStats {
        var totalTastings: Int = 0
        var uniqueBottles: Int = 0
        var averageRating: Double = 0.0
        var topCategory: String?
        var favoriteDistillery: String?
    }
    
    func loadLibrary() async {
        isLoading = true
        
        // Load stats
        // Load lists
        // Load recent tastings
        
        // Mock data
        defaultLists = [
            WhiskyList(
                id: "favorites",
                name: "Favorites",
                description: "Your top-rated whiskies",
                iconName: "star.fill",
                iconColor: .yellow,
                bottleCount: 23,
                isDefault: true
            ),
            WhiskyList(
                id: "collection",
                name: "My Collection",
                description: "Bottles you own",
                iconName: "books.vertical.fill",
                iconColor: .blue,
                bottleCount: 45,
                isDefault: true
            ),
            WhiskyList(
                id: "wishlist",
                name: "Wishlist",
                description: "Want to try",
                iconName: "sparkles",
                iconColor: .purple,
                bottleCount: 12,
                isDefault: true
            ),
            WhiskyList(
                id: "top-rated",
                name: "Top Rated",
                description: "Your 4.5+ star tastings",
                iconName: "trophy.fill",
                iconColor: .orange,
                bottleCount: 15,
                isDefault: true
            )
        ]
        
        stats = LibraryStats(
            totalTastings: 234,
            uniqueBottles: 89,
            averageRating: 4.2,
            topCategory: "Scotch",
            favoriteDistillery: "Ardbeg"
        )
        
        isLoading = false
    }
    
    func searchLibrary(_ query: String) {
        // Search across all lists
    }
    
    func refresh() async {
        await loadLibrary()
    }
}

// MARK: - Models
struct WhiskyList: Identifiable {
    let id: String
    let name: String
    let description: String?
    let iconName: String
    let iconColor: Color
    let bottleCount: Int
    let isDefault: Bool
    let isCustom: Bool = false
}
```

## Features

### Statistics Overview
- **Journey Card**: Key metrics at a glance
- **Total Tastings**: All-time count
- **Unique Bottles**: Distinct whiskies tried
- **Average Rating**: Overall preference
- **Detailed Stats**: Deep dive analytics

### List Management
- **Default Lists**:
  - Favorites (auto-populated from 4.5+ ratings)
  - My Collection (bottles owned)
  - Wishlist (want to try)
  - Top Rated (best of the best)
- **Custom Lists**: User-created collections
- **List Operations**: Create, edit, delete, share

### Search & Filter
- **Global Search**: Across all lists
- **List Search**: Within specific list
- **Category Filters**: By whisky type
- **Sort Options**:
  - Date added
  - Name (A-Z, Z-A)
  - Rating (high to low)
  - ABV
  - Price (when available)

### View Modes
- **Grid View**: Visual bottle display
- **List View**: Detailed information
- **Toggle**: Quick switch between modes
- **Responsive**: Adapts to screen size

### Recent Activity
- Latest 5 tastings
- Quick access to full history
- Visual rating display
- Relative timestamps

## Navigation

### From Library
- List → List detail
- Bottle → Bottle detail
- Tasting → Tasting detail
- Stats → Detailed analytics
- Create list → New list flow

### To Library
- Tab bar navigation
- After creating tasting
- From bottle detail (add to list)

## Data Management

### List Rules
- **Favorites**: Auto-added when rating ≥ 4.5
- **Collection**: Manual management
- **Wishlist**: Added from bottle detail
- **Custom**: User-defined criteria

### Sorting Logic
- Persistent per list
- Applies to search results
- Smooth animations
- Clear indicators

### Statistics Calculation
- Real-time updates
- Cached for performance
- Background refresh
- Interesting insights

## User Experience

### Empty States
- No lists: Create first list CTA
- Empty list: Add bottles prompt
- No tastings: Start journey message

### Visual Design
- Card-based layout
- Clear hierarchy
- Consistent spacing
- Platform conventions

### Performance
- Lazy loading lists
- Efficient image caching
- Smooth scrolling
- Quick searches

## Detailed Stats View (Future)

### Insights
- Tasting frequency graph
- Category breakdown
- Rating distribution
- Price analysis
- Regional preferences

### Achievements
- Milestones reached
- Rare bottles found
- Tasting streaks
- Collection value

### Comparisons
- vs. Community averages
- vs. Friends
- Personal trends
- Recommendations

## Accessibility

- List navigation announced
- Statistics read clearly
- Sort options accessible
- Grid/list toggle labeled

## Future Enhancements

- Export lists (CSV, PDF)
- Share lists with friends
- Collaborative lists
- Smart lists (auto-filters)
- Collection valuation
- Insurance documentation