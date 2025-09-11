# Bottle Detail Screen

## Overview

The Bottle Detail screen displays comprehensive information about a specific whisky, including details, ratings, recent tastings, and the ability to add it to your library or create a tasting.

## Visual Layout

```
┌─────────────────────────────────────────┐
│  ← Back                          •••    │
├─────────────────────────────────────────┤
│                                         │
│         [Large Bottle Image]            │
│                                         │
│                                         │
├─────────────────────────────────────────┤
│                                         │
│  Lagavulin 16 Year Old                  │
│  Lagavulin Distillery                   │
│                                         │
│  ★★★★☆ 4.5 (823 ratings)               │
│                                         │
│  Single Malt • Islay • 43% ABV          │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │        Check In                 │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌───────────┐ ┌───────────────────┐   │
│  │ ♡ Wishlist│ │ ✓ I've Had This   │   │
│  └───────────┘ └───────────────────┘   │
│                                         │
│  ─────────────────────────────────      │
│                                         │
│  About                                  │
│  Lagavulin 16 is a powerful Islay      │
│  single malt with intense peat smoke,   │
│  maritime notes, and a long finish...   │
│                                         │
│  ─────────────────────────────────      │
│                                         │
│  Your Activity                          │
│  You've had this 3 times               │
│  Average rating: ★★★★☆ 4.3             │
│  [View Your Tastings →]                 │
│                                         │
│  ─────────────────────────────────      │
│                                         │
│  Friends Activity                       │
│  [Avatar] Sarah rated ★★★★★            │
│  [Avatar] Mike rated ★★★★☆             │
│  [See all 5 friends →]                 │
│                                         │
│  ─────────────────────────────────      │
│                                         │
│  Recent Activity                        │
│  ┌─────────────────────────────────┐   │
│  │ [Mini TastingCard]              │   │
│  │ Tom rated ★★★★☆                 │   │
│  │ "Classic Lagavulin..."          │   │
│  └─────────────────────────────────┘   │
│                                         │
│  [View all 823 tastings →]             │
│                                         │
└─────────────────────────────────────────┘
```

## Implementation

```swift
import SwiftUI

struct BottleDetailScreen: View {
    let bottleId: String
    @StateObject private var viewModel: BottleDetailViewModel
    @State private var showingCheckIn = false
    @State private var showingShareSheet = false
    @State private var selectedTab = 0
    @Environment(\.dismiss) private var dismiss
    
    init(bottleId: String) {
        self.bottleId = bottleId
        self._viewModel = StateObject(wrappedValue: BottleDetailViewModel(bottleId: bottleId))
    }
    
    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                loadingView
                
            case .loaded(let bottle):
                loadedView(bottle)
                
            case .error(let message):
                errorView(message)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingShareSheet = true }) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: { /* Report */ }) {
                        Label("Report Issue", systemImage: "flag")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .task {
            await viewModel.loadBottle()
        }
        .sheet(isPresented: $showingCheckIn) {
            if let bottle = viewModel.bottle {
                NavigationView {
                    CreateTastingFlow(preselectedBottle: bottle)
                }
            }
        }
    }
    
    // MARK: - Loading View
    @ViewBuilder
    private var loadingView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Image placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 300)
                    .padding(.horizontal)
                
                // Content placeholders
                VStack(alignment: .leading, spacing: 12) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 24)
                        .frame(maxWidth: 200)
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 20)
                        .frame(maxWidth: 150)
                }
                .padding(.horizontal)
            }
            .redacted(reason: .placeholder)
            .shimmering()
        }
    }
    
    // MARK: - Loaded View
    @ViewBuilder
    private func loadedView(_ bottle: Bottle) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero section
                heroSection(bottle)
                
                // Action buttons
                actionButtons(bottle)
                    .padding(.horizontal)
                    .padding(.vertical, 20)
                
                Divider()
                    .padding(.vertical, 8)
                
                // Content sections
                VStack(spacing: 24) {
                    if let description = bottle.description {
                        aboutSection(description)
                    }
                    
                    if viewModel.userStats != nil {
                        userActivitySection
                    }
                    
                    if !viewModel.friendsTastings.isEmpty {
                        friendsActivitySection
                    }
                    
                    recentActivitySection
                    
                    similarBottlesSection
                }
                .padding(.vertical, 16)
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
    
    // MARK: - Hero Section
    @ViewBuilder
    private func heroSection(_ bottle: Bottle) -> some View {
        VStack(spacing: 16) {
            // Bottle image with parallax
            GeometryReader { geometry in
                let minY = geometry.frame(in: .global).minY
                let height: CGFloat = 300
                
                AsyncImage(url: URL(string: bottle.imageUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } placeholder: {
                    Image("BottlePlaceholder")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                }
                .frame(width: geometry.size.width, height: height + (minY > 0 ? minY : 0))
                .clipped()
                .offset(y: minY > 0 ? -minY : 0)
            }
            .frame(height: 300)
            
            // Bottle info
            VStack(spacing: 12) {
                Text(bottle.name)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                if let brand = bottle.brand {
                    Button(action: { /* Navigate to brand */ }) {
                        Text(brand.name)
                            .font(.body)
                            .foregroundColor(.accentColor)
                    }
                }
                
                // Rating
                HStack(spacing: 8) {
                    RatingView(rating: bottle.avgRating, size: 20)
                    
                    Text(String(format: "%.1f", bottle.avgRating))
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("(\(bottle.totalTastings) ratings)")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                // Metadata
                HStack(spacing: 8) {
                    if let category = bottle.category {
                        Tag(text: category.displayName)
                    }
                    
                    if let region = bottle.distillery?.region {
                        Tag(text: region)
                    }
                    
                    if let abv = bottle.abv {
                        Tag(text: "\(abv, specifier: "%.1f")% ABV")
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Action Buttons
    @ViewBuilder
    private func actionButtons(_ bottle: Bottle) -> some View {
        VStack(spacing: 12) {
            // Primary CTA
            Button(action: { showingCheckIn = true }) {
                Label("Check In", systemImage: "plus.circle.fill")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentColor)
                    .cornerRadius(12)
            }
            
            // Secondary actions
            HStack(spacing: 12) {
                Button(action: { 
                    Task {
                        await viewModel.toggleWishlist()
                    }
                }) {
                    Label(
                        bottle.isWishlist ? "In Wishlist" : "Wishlist",
                        systemImage: bottle.isWishlist ? "heart.fill" : "heart"
                    )
                    .font(.body)
                    .foregroundColor(bottle.isWishlist ? .white : .accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        bottle.isWishlist 
                            ? Color.accentColor 
                            : Color.accentColor.opacity(0.1)
                    )
                    .cornerRadius(10)
                }
                
                Button(action: { 
                    Task {
                        await viewModel.toggleHasHad()
                    }
                }) {
                    Label(
                        bottle.hasHad ? "I've Had This" : "Mark as Had",
                        systemImage: bottle.hasHad ? "checkmark.circle.fill" : "circle"
                    )
                    .font(.body)
                    .foregroundColor(bottle.hasHad ? .white : .accentColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        bottle.hasHad 
                            ? Color.green 
                            : Color.green.opacity(0.1)
                    )
                    .cornerRadius(10)
                }
            }
        }
    }
    
    // MARK: - About Section
    @ViewBuilder
    private func aboutSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About")
                .font(.headline)
                .padding(.horizontal)
            
            Text(description)
                .font(.body)
                .foregroundColor(.primary)
                .padding(.horizontal)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - User Activity Section
    @ViewBuilder
    private var userActivitySection: some View {
        if let stats = viewModel.userStats {
            VStack(alignment: .leading, spacing: 12) {
                Text("Your Activity")
                    .font(.headline)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    if stats.tastingCount > 0 {
                        Text("You've had this \(stats.tastingCount) time\(stats.tastingCount == 1 ? "" : "s")")
                            .font(.body)
                        
                        HStack {
                            Text("Average rating:")
                                .font(.body)
                            
                            RatingView(rating: stats.averageRating, size: 16)
                            
                            Text(String(format: "%.1f", stats.averageRating))
                                .font(.body)
                                .fontWeight(.medium)
                        }
                        
                        NavigationLink(destination: UserTastingsView(bottle: viewModel.bottle!)) {
                            Text("View Your Tastings")
                                .font(.body)
                                .foregroundColor(.accentColor)
                            Image(systemName: "arrow.right")
                                .font(.caption)
                                .foregroundColor(.accentColor)
                        }
                    } else {
                        Text("You haven't tried this yet")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Friends Activity Section
    @ViewBuilder
    private var friendsActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Friends Activity")
                    .font(.headline)
                
                Spacer()
                
                if viewModel.friendsTastings.count > 3 {
                    NavigationLink(destination: FriendsTastingsView(bottle: viewModel.bottle!)) {
                        Text("See all \(viewModel.friendsTastings.count)")
                            .font(.caption)
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .padding(.horizontal)
            
            VStack(spacing: 0) {
                ForEach(viewModel.friendsTastings.prefix(3)) { tasting in
                    HStack {
                        UserAvatar(user: tasting.user, size: 40)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(tasting.user?.displayName ?? "")
                                .font(.body)
                                .fontWeight(.medium)
                            
                            HStack(spacing: 4) {
                                Text("rated")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                RatingView(rating: tasting.rating, size: 12)
                            }
                        }
                        
                        Spacer()
                        
                        Text(tasting.createdAt.relativeTime)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    
                    if tasting != viewModel.friendsTastings.prefix(3).last {
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    // MARK: - Recent Activity Section
    @ViewBuilder
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink(destination: AllTastingsView(bottle: viewModel.bottle!)) {
                    Text("View all \(viewModel.bottle?.totalTastings ?? 0)")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal)
            
            if viewModel.recentTastings.isEmpty {
                Text("No tastings yet. Be the first!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
            } else {
                VStack(spacing: 16) {
                    ForEach(viewModel.recentTastings.prefix(3)) { tasting in
                        MiniTastingCard(
                            tasting: tasting,
                            onTap: {
                                // Navigate to tasting detail
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Similar Bottles Section
    @ViewBuilder
    private var similarBottlesSection: some View {
        if !viewModel.similarBottles.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Similar Bottles")
                    .font(.headline)
                    .padding(.horizontal)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(viewModel.similarBottles) { bottle in
                            NavigationLink(destination: BottleDetailScreen(bottleId: bottle.id)) {
                                SimilarBottleCard(bottle: bottle)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Error View
    @ViewBuilder
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            
            Text("Unable to load bottle")
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                Task {
                    await viewModel.loadBottle()
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
}

// MARK: - Supporting Views
struct MiniTastingCard: View {
    let tasting: Tasting
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    UserAvatar(user: tasting.user, size: 32)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tasting.user?.displayName ?? "")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 4) {
                            RatingView(rating: tasting.rating, size: 12)
                            Text(String(format: "%.1f", tasting.rating))
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    Spacer()
                    
                    Text(tasting.createdAt.relativeTime)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let notes = tasting.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "hands.clap")
                            .font(.caption)
                        Text("\(tasting.toastCount)")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left")
                            .font(.caption)
                        Text("\(tasting.commentCount)")
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                    
                    Spacer()
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct SimilarBottleCard: View {
    let bottle: Bottle
    
    var body: some View {
        VStack(spacing: 8) {
            AsyncImage(url: URL(string: bottle.imageUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } placeholder: {
                Image("BottlePlaceholder")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            }
            .frame(width: 80, height: 120)
            
            VStack(spacing: 4) {
                Text(bottle.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: 2) {
                    RatingView(rating: bottle.avgRating, size: 10)
                    Text(String(format: "%.1f", bottle.avgRating))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: 120)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - View Model
@MainActor
class BottleDetailViewModel: ObservableObject {
    @Published var state: ViewState = .loading
    @Published var bottle: Bottle?
    @Published var userStats: UserBottleStats?
    @Published var friendsTastings: [Tasting] = []
    @Published var recentTastings: [Tasting] = []
    @Published var similarBottles: [Bottle] = []
    
    private let bottleId: String
    private let repository: BottleRepository
    
    enum ViewState {
        case loading
        case loaded(Bottle)
        case error(String)
    }
    
    init(bottleId: String, repository: BottleRepository = BottleRepositoryImpl()) {
        self.bottleId = bottleId
        self.repository = repository
    }
    
    func loadBottle() async {
        state = .loading
        
        do {
            async let bottle = repository.getBottle(id: bottleId)
            async let userStats = repository.getUserStats(bottleId: bottleId)
            async let friendsTastings = repository.getFriendsTastings(bottleId: bottleId)
            async let recentTastings = repository.getRecentTastings(bottleId: bottleId)
            async let similarBottles = repository.getSimilarBottles(bottleId: bottleId)
            
            let (
                loadedBottle,
                loadedUserStats,
                loadedFriendsTastings,
                loadedRecentTastings,
                loadedSimilarBottles
            ) = try await (
                bottle,
                userStats,
                friendsTastings,
                recentTastings,
                similarBottles
            )
            
            self.bottle = loadedBottle
            self.userStats = loadedUserStats
            self.friendsTastings = loadedFriendsTastings
            self.recentTastings = loadedRecentTastings
            self.similarBottles = loadedSimilarBottles
            
            state = .loaded(loadedBottle)
        } catch {
            state = .error(error.localizedDescription)
        }
    }
    
    func refresh() async {
        await loadBottle()
    }
    
    func toggleWishlist() async {
        guard let bottle = bottle else { return }
        
        // Optimistic update
        withAnimation {
            self.bottle?.isWishlist.toggle()
        }
        
        do {
            if bottle.isWishlist {
                try await repository.removeFromWishlist(bottleId: bottleId)
            } else {
                try await repository.addToWishlist(bottleId: bottleId)
            }
        } catch {
            // Revert on error
            withAnimation {
                self.bottle?.isWishlist.toggle()
            }
        }
    }
    
    func toggleHasHad() async {
        guard let bottle = bottle else { return }
        
        // Optimistic update
        withAnimation {
            self.bottle?.hasHad.toggle()
        }
        
        do {
            if bottle.hasHad {
                try await repository.markAsNotHad(bottleId: bottleId)
            } else {
                try await repository.markAsHad(bottleId: bottleId)
            }
        } catch {
            // Revert on error
            withAnimation {
                self.bottle?.hasHad.toggle()
            }
        }
    }
}

// MARK: - Supporting Models
struct UserBottleStats {
    let tastingCount: Int
    let averageRating: Double
    let firstTasted: Date?
    let lastTasted: Date?
}
```

## Navigation

### Entry Points
- Search results tap
- Tasting card bottle tap
- Barcode scan result
- Deep link
- Similar bottles

### Exit Points
- Check in → Create tasting flow
- Brand/distillery links
- User tastings list
- Friends tastings list
- All tastings list
- Similar bottle → Another bottle detail

## Features

### Hero Section
- Parallax scrolling image
- High-res bottle photo
- Fade to background on scroll

### User Tracking
- Wishlist toggle
- "I've had this" marking
- Personal statistics
- Tasting history link

### Social Proof
- Average rating display
- Total ratings count
- Friends who've tried it
- Recent community activity

### Discovery
- Similar bottles carousel
- Brand/distillery links
- Related categories

## Data Loading

### Parallel Requests
- Bottle details
- User statistics
- Friends tastings
- Recent tastings
- Similar bottles

### Caching Strategy
- Cache bottle details for session
- Refresh on pull-to-refresh
- Update counts in real-time

## State Management

### Local State
- Loading/error states
- Sheet presentations
- User interactions

### Optimistic Updates
- Wishlist toggle
- Has had toggle
- Immediate UI feedback

## Accessibility

- Image descriptions
- Rating announcements
- Action button labels
- Grouped related content

## Performance

- Lazy load sections
- Image caching
- Parallel data fetching
- Smooth animations

## Error Handling

- Network failures
- Missing bottle (404)
- Graceful degradation
- Retry mechanisms