import AVFoundation
import PeatedCore
import PhotosUI
import SwiftUI
import VisionKit

struct BottleSelectionStep: View {
    @Environment(\.openURL) private var openURL
    @ObservedObject var viewModel: CreateTastingViewModel
    @State private var searchText = ""
    @State private var showingScanner = false
    @State private var showingLabelScanner = false
    @State private var showingPhotoResolution = false
    @State private var showingManualEntry = false
    @State private var showingCameraPermissionAlert = false
    @State private var showingLabelScannerUnavailableAlert = false
    @State private var bottlePhotoItem: PhotosPickerItem?
    @State private var bottlePhoto: UIImage?
    @FocusState private var isSearchFocused: Bool
    var onBottleSelected: (() -> Void)?

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

                        // Camera scanner buttons
                        if !viewModel.isSearching, searchText.isEmpty {
                            scannerButtons
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
                    if !viewModel
                        .isSearching ||
                        (viewModel.isSearching && viewModel.searchResults.isEmpty && !searchText.isEmpty) {
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
        .sheet(isPresented: $showingLabelScanner, onDismiss: presentPhotoResolutionIfNeeded) {
            BottleLabelScannerView { image in
                bottlePhoto = image
            }
        }
        .sheet(isPresented: $showingPhotoResolution, onDismiss: clearBottlePhoto) {
            if let bottlePhoto {
                BottlePhotoResolutionView(
                    image: bottlePhoto,
                    onBottleResolved: handlePhotoResolved,
                    onSearch: handlePhotoSearch
                )
            }
        }
        .sheet(isPresented: $showingManualEntry) {
            ManualBottleEntryView { bottle in
                selectBottle(bottle)
            }
        }
        .alert("Camera Access Needed", isPresented: $showingCameraPermissionAlert) {
            Button("Open Settings") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    openURL(settingsURL)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Allow camera access in Settings to scan bottle labels and barcodes.")
        }
        .alert("Label Scanner Unavailable", isPresented: $showingLabelScannerUnavailableAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(
                "Live label scanning requires a supported physical device. " +
                    "Choose a bottle photo instead, or search by name."
            )
        }
        .task {
            await loadRecentBottles()
        }
        .onChange(of: bottlePhotoItem) { _, item in
            guard let item else { return }
            Task { await loadBottlePhoto(item) }
        }
    }

    // MARK: - Search Bar

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

    // MARK: - Scanner Buttons

    private var scannerButtons: some View {
        VStack(spacing: 10) {
            Button {
                checkCameraPermissionAndScan(.label)
            } label: {
                HStack {
                    Image(systemName: "text.viewfinder")
                        .font(.title3)
                    Text("Take Bottle Photo")
                        .font(.body)
                        .fontWeight(.medium)
                }
                .foregroundColor(.onBrand)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.brand)
                .cornerRadius(10)
            }

            PhotosPicker(selection: $bottlePhotoItem, matching: .images) {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title3)
                    Text("Choose Bottle Photo")
                        .font(.body)
                        .fontWeight(.medium)
                }
                .foregroundColor(.brand)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.brand.opacity(0.1))
                .cornerRadius(10)
            }

            Button {
                checkCameraPermissionAndScan(.barcode)
            } label: {
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
    }

    // MARK: - Search Results

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
            } else if viewModel.searchResults.isEmpty, searchText.count > 2 {
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

    private var cantFindBottleSection: some View {
        VStack(spacing: 8) {
            Text("Can't find your bottle?")
                .font(.body)
                .foregroundColor(.textSecondary)

            Button {
                showingManualEntry = true
            } label: {
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
        .background(Color.formSurface)
        .cornerRadius(12)
    }

    // MARK: - Actions

    private func selectBottle(_ bottle: Bottle, pendingImageId: String? = nil) {
        withAnimation {
            viewModel.selectedBottle = bottle
            viewModel.pendingBottlePhotoId = pendingImageId
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

    private func checkCameraPermissionAndScan(_ destination: ScannerDestination) {
        if destination == .label, !DataScannerViewController.isSupported {
            showingLabelScannerUnavailableAlert = true
            return
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showScanner(destination)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showScanner(destination)
                    } else {
                        showingCameraPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            showingCameraPermissionAlert = true
        @unknown default:
            showingCameraPermissionAlert = true
        }
    }

    private func showScanner(_ destination: ScannerDestination) {
        switch destination {
        case .label:
            guard DataScannerViewController.isAvailable else {
                showingLabelScannerUnavailableAlert = true
                return
            }
            showingLabelScanner = true
        case .barcode:
            showingScanner = true
        }
    }

    private func handleBarcodeScanned(_ barcode: String) {
        Task {
            if let bottle = await viewModel.bottleForBarcode(barcode) {
                selectBottle(bottle)
            }
        }
    }

    private func loadBottlePhoto(_ item: PhotosPickerItem) async {
        defer { bottlePhotoItem = nil }

        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data)
        else {
            viewModel.errorMessage = "We couldn't load that photo. Choose another image and try again."
            viewModel.showingError = true
            return
        }

        bottlePhoto = image
        showingPhotoResolution = true
    }

    private func presentPhotoResolutionIfNeeded() {
        if bottlePhoto != nil {
            showingPhotoResolution = true
        }
    }

    private func clearBottlePhoto() {
        if !showingLabelScanner {
            bottlePhoto = nil
        }
    }

    private func handlePhotoResolved(_ bottle: Bottle, pendingImageId: String) {
        showingPhotoResolution = false
        selectBottle(bottle, pendingImageId: pendingImageId)
    }

    private func handlePhotoSearch(_ query: String) {
        showingPhotoResolution = false
        searchText = query
    }

    private func getLastTasting(for _: Bottle) -> TastingFeedItem? {
        // TODO: Get user's last tasting of this bottle
        nil
    }

    private enum ScannerDestination: Sendable {
        case label
        case barcode
    }
}
