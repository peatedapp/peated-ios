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
                        .foregroundColor(.text)
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
            .background(Color.background)
        }
        .background(Color.background)
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
        SearchInput(placeholder: "Search for a bottle...", text: $searchText, onSubmit: {
            Task { await searchBottles() }
        })
        .onChange(of: searchText) { _, newValue in
            if newValue.isEmpty {
                viewModel.searchResults = []
            } else {
                searchBottlesDebounced(newValue)
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
            .foregroundColor(.brand)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.brand.opacity(0.1))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Search Results
    @ViewBuilder
    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Search Results")
                .font(.headline)
                .foregroundColor(.textSecondary)
                .padding(.horizontal)
            
            if viewModel.isSearching {
                // Loading state
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.2)
                    
                    Text("Searching...")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else if viewModel.searchResults.isEmpty && searchText.count > 2 {
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.textSecondary)
                    
                    Text("No bottles found")
                        .font(.body)
                        .foregroundColor(.textSecondary)
                    
                    Text("Try a different search or add it manually")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ForEach(viewModel.searchResults) { bottle in
                    BottleRow(
                        bottle: bottle,
                        isSelected: viewModel.selectedBottle?.id == bottle.id,
                        subtitle: .rating,
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
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal)
                
                ForEach(viewModel.recentBottles) { bottle in
                    BottleRow(
                        bottle: bottle,
                        isSelected: viewModel.selectedBottle?.id == bottle.id,
                        subtitle: getLastTasting(for: bottle).map { .lastTasting($0) },
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
                .foregroundColor(.textSecondary)
            
            Button(action: {
                showingManualEntry = true
            }) {
                HStack {
                    Text("Add it manually")
                    Image(systemName: "arrow.right")
                        .font(.caption)
                }
                .font(.body)
                .foregroundColor(.brand)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.surface)
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
        Task {
            // Search for bottle by barcode
            searchText = barcode
            await viewModel.searchBottles(query: barcode)
            
            // If we found exactly one result, select it automatically
            if viewModel.searchResults.count == 1,
               let bottle = viewModel.searchResults.first {
                selectBottle(bottle)
            }
        }
    }
    
    private func getLastTasting(for bottle: Bottle) -> TastingFeedItem? {
        // TODO: Get user's last tasting of this bottle
        nil
    }
}

