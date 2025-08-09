import SwiftUI
import AVFoundation
import PeatedCore

struct BottleSelectionStep: View {
    @ObservedObject var viewModel: CreateTastingViewModel
    @State private var searchText = ""
    @State private var showingScanner = false
    @State private var showingManualEntry = false
    @FocusState private var isSearchFocused: Bool
    var onBottleSelected: (() -> Void)? = nil
    
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
                        if !viewModel.isSearching && searchText.isEmpty {
                            scanBarcodeButton
                        }
                    }
                    .padding(.horizontal)
                    
                    // Content based on state
                    if viewModel.isSearching || !searchText.isEmpty {
                        searchResultsSection
                    } else {
                        recentBottlesSection
                    }
                    
                    // Can't find bottle link
                    if !viewModel.isSearching || (viewModel.isSearching && viewModel.searchResults.isEmpty && !searchText.isEmpty) {
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
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .submitLabel(.search)
                .focused($isSearchFocused)
                .onSubmit {
                    Task { await searchBottles() }
                }
                .onChange(of: searchText) { _, newValue in
                    if newValue.isEmpty {
                        viewModel.searchResults = []
                    } else {
                        searchBottlesDebounced(newValue)
                    }
                }
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                    viewModel.searchResults = []
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
            
            if viewModel.isSearching {
                // Loading state
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.2)
                    
                    Text("Searching...")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else if viewModel.searchResults.isEmpty && searchText.count > 2 {
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
                ForEach(viewModel.searchResults) { bottle in
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
        if !viewModel.recentBottles.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Text("Recent Bottles")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                ForEach(viewModel.recentBottles) { bottle in
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
        
        // Automatically advance to next step
        onBottleSelected?()
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
        await viewModel.searchBottles(query: searchText)
    }
    
    private func loadRecentBottles() async {
        await viewModel.loadRecentBottles()
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
            // TODO: Show alert to go to settings
            break
        }
    }
    
    private func handleBarcodeScanned(_ barcode: String) {
        // TODO: Look up bottle by barcode
        Task {
            // Search for bottle by barcode
            // If found, select it
            // If not found, show not found message
        }
    }
    
    private func getLastTasting(for bottle: Bottle) -> TastingFeedItem? {
        // TODO: Get user's last tasting of this bottle
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
                    Image(systemName: "wineglass")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .frame(width: 50, height: 70)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .frame(width: 50, height: 70)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(bottle.fullName)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(bottle.brandName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 4) {
                        if let category = bottle.category {
                            Text(category.capitalized)
                        }
                        
                        if let abv = bottle.abv {
                            Text("• \(abv, specifier: "%.1f")%")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    if bottle.totalRatings > 0 {
                        HStack(spacing: 4) {
                            RatingView(rating: bottle.avgRating, size: 12)
                            Text(String(format: "%.1f", bottle.avgRating))
                                .font(.caption)
                                .foregroundColor(.primary)
                            Text("(\(bottle.totalRatings))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
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
    let lastTasting: TastingFeedItem?
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
                    Image(systemName: "wineglass")
                        .font(.title2)
                        .foregroundColor(.secondary)
                        .frame(width: 50, height: 70)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                .frame(width: 50, height: 70)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(bottle.fullName)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(bottle.brandName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let tasting = lastTasting {
                        HStack(spacing: 4) {
                            RatingView(rating: tasting.rating, size: 12)
                            Text("Your rating")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text("Last had: \(tasting.createdAt, format: .relative(presentation: .named))")
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

// MARK: - Placeholder Views (TODO: Implement)
struct BarcodeScannerView: View {
    let onBarcodeScanned: (String) -> Void
    
    var body: some View {
        Text("Barcode Scanner")
            .navigationTitle("Scan Barcode")
    }
}

struct ManualBottleEntryView: View {
    let onBottleCreated: (Bottle) -> Void
    
    var body: some View {
        Text("Manual Bottle Entry")
            .navigationTitle("Add Bottle")
    }
}

// MARK: - Rating View
struct RatingView: View {
    let rating: Double
    let size: CGFloat
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...5, id: \.self) { star in
                Image(systemName: star <= Int(rating.rounded()) ? "star.fill" : "star")
                    .font(.system(size: size))
                    .foregroundColor(.yellow)
            }
        }
    }
}