# Bottle Selection Step

## Overview

The first step of the tasting creation flow allows users to select the whisky they're drinking. This step supports search, barcode scanning, recent selections, and manual entry for bottles not in the database.

## Visual Layout

```
┌─────────────────────────────────────────┐
│  ✕ Cancel          Check In (1/5)       │
├─────────────────────────────────────────┤
│                                         │
│  What are you drinking?                 │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ 🔍 Search for a bottle...       │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │      📷 Scan Barcode            │   │
│  └─────────────────────────────────┘   │
│                                         │
│  Recent Bottles                         │
│  ┌─────────────────────────────────┐   │
│  │ [Bottle] Ardbeg 10              │   │
│  │         ★★★★☆ Your rating       │   │
│  │         Last had: 3 days ago    │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ [Bottle] Macallan 18            │   │
│  │         ★★★★★ Your rating       │   │
│  │         Last had: 1 week ago    │   │
│  └─────────────────────────────────┘   │
│                                         │
│  Can't find your bottle?               │
│  [Add it manually →]                    │
│                                         │
├─────────────────────────────────────────┤
│                          Continue →     │
└─────────────────────────────────────────┘
```

### Search Active State
```
┌─────────────────────────────────────────┐
│  ✕ Cancel          Check In (1/5)       │
├─────────────────────────────────────────┤
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ 🔍 Lagavulin                  ✕ │   │
│  └─────────────────────────────────┘   │
│                                         │
│  Search Results                         │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ [Bottle] Lagavulin 16          │   │
│  │         Single Malt • 43%       │   │
│  │         ★★★★☆ 4.5 (823)        │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ [Bottle] Lagavulin 8           │   │
│  │         Single Malt • 43%       │   │
│  │         ★★★★☆ 4.3 (412)        │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ [Bottle] Lagavulin 12 (2021)   │   │
│  │         Cask Strength • 56.5%   │   │
│  │         ★★★★☆ 4.6 (234)        │   │
│  └─────────────────────────────────┘   │
│                                         │
└─────────────────────────────────────────┘
```

## Implementation

```swift
import SwiftUI
import AVFoundation

struct BottleSelectionStep: View {
    @ObservedObject var viewModel: CreateTastingViewModel
    @State private var searchText = ""
    @State private var isSearching = false
    @State private var searchResults: [Bottle] = []
    @State private var recentBottles: [Bottle] = []
    @State private var showingScanner = false
    @State private var showingManualEntry = false
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    Text("What are you drinking?")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    VStack(spacing: 12) {
                        // Search bar
                        searchBar
                        
                        // Barcode scanner button
                        if !isSearching {
                            scanBarcodeButton
                        }
                    }
                    .padding(.horizontal)
                    
                    // Content based on state
                    if isSearching && !searchText.isEmpty {
                        searchResultsSection
                    } else if !isSearching {
                        recentBottlesSection
                    }
                    
                    // Can't find bottle link
                    if !isSearching || (isSearching && searchResults.isEmpty && !searchText.isEmpty) {
                        cantFindBottleSection
                            .padding(.horizontal)
                            .padding(.vertical)
                    }
                }
                .padding(.bottom, 100) // Space for navigation buttons
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .sheet(isPresented: $showingScanner) {
            BarcodeScannerView { barcode in
                handleBarcodeScanned(barcode)
            }
        }
        .sheet(isPresented: $showingManualEntry) {
            ManualBottleEntryView { bottle in
                viewModel.selectedBottle = bottle
            }
        }
        .task {
            await loadRecentBottles()
        }
    }
    
    // MARK: - Search Bar
    @ViewBuilder
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search for a bottle...", text: $searchText)
                .textFieldStyle(.plain)
                .focused($isSearchFocused)
                .onSubmit {
                    searchBottles()
                }
                .onChange(of: searchText) { newValue in
                    if newValue.isEmpty {
                        searchResults = []
                    } else {
                        searchBottlesDebounced(newValue)
                    }
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    searchResults = []
                    isSearchFocused = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSearchFocused ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .onChange(of: isSearchFocused) { focused in
            withAnimation {
                isSearching = focused
            }
        }
    }
    
    // MARK: - Scan Barcode Button
    @ViewBuilder
    private var scanBarcodeButton: some View {
        Button(action: {
            checkCameraPermissionAndScan()
        }) {
            HStack {
                Image(systemName: "barcode.viewfinder")
                    .font(.title3)
                Text("Scan Barcode")
                    .font(.body)
                    .fontWeight(.medium)
            }
            .foregroundColor(.accentColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Search Results
    @ViewBuilder
    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Search Results")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            if searchResults.isEmpty && searchText.count > 2 {
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("No bottles found")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text("Try a different search or add it manually")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(searchResults) { bottle in
                    BottleSearchRow(
                        bottle: bottle,
                        isSelected: viewModel.selectedBottle?.id == bottle.id,
                        onTap: {
                            selectBottle(bottle)
                        }
                    )
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Recent Bottles
    @ViewBuilder
    private var recentBottlesSection: some View {
        if !recentBottles.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Bottles")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                ForEach(recentBottles) { bottle in
                    RecentBottleRow(
                        bottle: bottle,
                        lastTasting: getLastTasting(for: bottle),
                        isSelected: viewModel.selectedBottle?.id == bottle.id,
                        onTap: {
                            selectBottle(bottle)
                        }
                    )
                    .padding(.horizontal)
                }
            }
        }
    }
    
    // MARK: - Can't Find Bottle
    @ViewBuilder
    private var cantFindBottleSection: some View {
        VStack(spacing: 8) {
            Text("Can't find your bottle?")
                .font(.body)
                .foregroundColor(.secondary)
            
            Button(action: {
                showingManualEntry = true
            }) {
                HStack {
                    Text("Add it manually")
                    Image(systemName: "arrow.right")
                        .font(.caption)
                }
                .font(.body)
                .foregroundColor(.accentColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    // MARK: - Actions
    private func selectBottle(_ bottle: Bottle) {
        withAnimation {
            viewModel.selectedBottle = bottle
            isSearchFocused = false
        }
        
        // Haptic feedback
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    private func searchBottlesDebounced(_ query: String) {
        // Implement debounced search
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000) // 300ms
            if searchText == query {
                await searchBottles()
            }
        }
    }
    
    private func searchBottles() async {
        // Implement bottle search
    }
    
    private func loadRecentBottles() async {
        // Load user's recent bottles
    }
    
    private func checkCameraPermissionAndScan() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showingScanner = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        showingScanner = true
                    }
                }
            }
        default:
            // Show alert to go to settings
            break
        }
    }
    
    private func handleBarcodeScanned(_ barcode: String) {
        // Look up bottle by barcode
        Task {
            // Search for bottle by barcode
            // If found, select it
            // If not found, show not found message
        }
    }
    
    private func getLastTasting(for bottle: Bottle) -> Tasting? {
        // Get user's last tasting of this bottle
        nil
    }
}

// MARK: - Bottle Search Row
struct BottleSearchRow: View {
    let bottle: Bottle
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
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
                .frame(width: 50, height: 70)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(bottle.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        if let category = bottle.category {
                            Text(category.displayName)
                        }
                        
                        if let abv = bottle.abv {
                            Text("• \(abv, specifier: "%.1f")%")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        RatingView(rating: bottle.avgRating, size: 12)
                        Text(String(format: "%.1f", bottle.avgRating))
                            .font(.caption)
                            .foregroundColor(.primary)
                        Text("(\(bottle.totalTastings))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.title3)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Recent Bottle Row
struct RecentBottleRow: View {
    let bottle: Bottle
    let lastTasting: Tasting?
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
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
                .frame(width: 50, height: 70)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(bottle.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if let tasting = lastTasting {
                        HStack(spacing: 4) {
                            RatingView(rating: tasting.rating, size: 12)
                            Text("Your rating")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Last had: \(tasting.createdAt.relativeTime)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.title3)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
```

## Features

### Search
- Real-time search with debouncing
- Shows bottle name, category, ABV
- Community ratings displayed
- Visual selection feedback

### Barcode Scanning
- Camera permission handling
- UPC/EAN barcode support
- Fallback to manual search
- Loading state during lookup

### Recent Bottles
- Last 10 unique bottles
- Shows user's rating
- "Last had" timestamp
- Quick re-selection

### Manual Entry
- For bottles not in database
- Basic fields: name, brand, ABV
- Creates pending bottle
- Syncs when online

## State Management

### Selection State
- Single bottle selection
- Visual confirmation
- Persists through navigation
- Enables "Continue" button

### Search State
- Debounced queries (300ms)
- Cancel previous searches
- Clear on selection
- Maintain during step navigation

## User Experience

### Empty States
- No recent bottles: Helpful message
- No search results: Add manually CTA
- Loading states: Skeleton views

### Feedback
- Haptic on selection
- Visual selection state
- Smooth animations
- Clear CTAs

## Error Handling

### Camera Permission
- Clear permission request
- Settings redirect if denied
- Graceful fallback

### Search Errors
- Network failure handling
- Timeout management
- User-friendly messages

### Barcode Not Found
- Clear messaging
- Manual search option
- Add new bottle flow

## Accessibility

- VoiceOver labels for all bottles
- Selection state announced
- Barcode scanner instructions
- Keyboard navigation support

## Performance

- Lazy load bottle images
- Efficient search queries
- Image caching
- Smooth 60fps scrolling