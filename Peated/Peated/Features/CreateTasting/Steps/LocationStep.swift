import SwiftUI
import CoreLocation
import PeatedCore

struct LocationStep: View {
    @ObservedObject var viewModel: CreateTastingViewModel
    @StateObject private var locationService = LocationService()
    @State private var searchText = ""
    @State private var searchResults: [Location] = []
    @State private var currentLocationInfo: Location?
    @State private var searchTask: Task<Void, Never>?
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Where are you sipping?")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.text)
                    
                    Text("Help others discover great spots")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                .padding(.horizontal)
                .padding(.top)
                
                VStack(spacing: 16) {
                    // At Home Option
                    HomeLocationButton(
                        isSelected: viewModel.isDrinkingAtHome,
                        onTap: {
                            withAnimation {
                                viewModel.isDrinkingAtHome.toggle()
                                if viewModel.isDrinkingAtHome {
                                    viewModel.selectedLocation = nil
                                }
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    )
                    
                    // Divider with "OR"
                    HStack {
                        Rectangle()
                            .fill(Color(.separator))
                            .frame(height: 1)
                        
                        Text("OR")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                            .padding(.horizontal, 8)
                        
                        Rectangle()
                            .fill(Color(.separator))
                            .frame(height: 1)
                    }
                    .padding(.horizontal)
                    
                    // Current Location Button
                    CurrentLocationButton(
                        isLoading: locationService.isLoadingLocation,
                        currentLocation: currentLocationInfo,
                        isSelected: viewModel.selectedLocation?.id == currentLocationInfo?.id,
                        onTap: {
                            if let location = currentLocationInfo {
                                selectLocation(location)
                            } else {
                                requestCurrentLocation()
                            }
                        }
                    )
                    
                    // Search Bar
                    LocationSearchBar(
                        searchText: $searchText,
                        isSearchFocused: $isSearchFocused,
                        onSearch: {
                            Task { await searchLocations() }
                        }
                    )
                    
                    // Search Results
                    if !searchResults.isEmpty {
                        LocationSearchResults(
                            results: searchResults,
                            selectedLocationId: viewModel.selectedLocation?.id,
                            onLocationSelected: selectLocation
                        )
                    }
                    
                    // Selected Location Display
                    if let selectedLocation = viewModel.selectedLocation,
                       !viewModel.isDrinkingAtHome {
                        SelectedLocationView(
                            location: selectedLocation,
                            onRemove: {
                                withAnimation {
                                    viewModel.selectedLocation = nil
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 100) // Space for navigation buttons
        }
        .background(Color.background)
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            locationService.requestLocationPermission()
        }
        .onChange(of: searchText) { _, newValue in
            // Cancel previous search task
            searchTask?.cancel()
            
            // Start new search with debounce
            searchTask = Task {
                try? await Task.sleep(nanoseconds: 500_000_000) // 500ms debounce
                if !Task.isCancelled {
                    await searchLocations()
                }
            }
        }
        .onChange(of: locationService.currentLocation) { _, newLocation in
            if let location = newLocation {
                Task {
                    currentLocationInfo = await locationService.reverseGeocodeLocation(location)
                }
            }
        }
    }
    
    private func selectLocation(_ location: Location) {
        withAnimation {
            viewModel.selectedLocation = location
            viewModel.isDrinkingAtHome = false
            searchText = ""
            searchResults = []
            isSearchFocused = false
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    private func requestCurrentLocation() {
        locationService.requestCurrentLocation()
    }
    
    private func searchLocations() async {
        guard !searchText.isEmpty else {
            searchResults = []
            return
        }
        
        // Use MapKit to search for places
        let results = await locationService.searchPlaces(query: searchText)
        
        // Update on main thread
        await MainActor.run {
            searchResults = results
        }
    }
}

// MARK: - Home Location Button
struct HomeLocationButton: View {
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: "house.fill")
                    .font(.title2)
                    .foregroundColor(isSelected ? .onBrand : .brand)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("At Home")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .onBrand : .text)
                    
                    Text("Just chilling")
                        .font(.caption)
                        .foregroundColor(isSelected ? .onBrand.opacity(0.9) : .textSecondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.onBrand)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.brand : Color.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.brand : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Current Location Button
struct CurrentLocationButton: View {
    let isLoading: Bool
    let currentLocation: Location?
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Group {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .brand))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "location.fill")
                            .font(.title2)
                            .foregroundColor(isSelected ? .onBrand : .brand)
                    }
                }
                .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(currentLocation?.name ?? "Use Current Location")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .onBrand : .text)
                    
                    if let address = currentLocation?.address {
                        Text(address)
                            .font(.caption)
                            .foregroundColor(isSelected ? .onBrand.opacity(0.9) : .textSecondary)
                            .lineLimit(2)
                    } else if !isLoading {
                        Text("Tap to find nearby places")
                            .font(.caption)
                            .foregroundColor(isSelected ? .onBrand.opacity(0.9) : .textSecondary)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.onBrand)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.brand : Color.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.brand : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }
}

// MARK: - Location Search Bar
struct LocationSearchBar: View {
    @Binding var searchText: String
    @FocusState.Binding var isSearchFocused: Bool
    let onSearch: () -> Void
    
    var body: some View {
        SearchInput(placeholder: "Search for a place...", text: $searchText, onSubmit: onSearch)
    }
}

// MARK: - Location Search Results
struct LocationSearchResults: View {
    let results: [Location]
    let selectedLocationId: String?
    let onLocationSelected: (Location) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Search Results")
                .font(.headline)
                .foregroundColor(.textSecondary)
            
            ForEach(results) { location in
                LocationRow(
                    location: location,
                    isSelected: selectedLocationId == location.id,
                    onTap: { onLocationSelected(location) }
                )
            }
        }
    }
}

// MARK: - Location Row
struct LocationRow: View {
    let location: Location
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "mappin.circle.fill")
                    .font(.title2)
                    .foregroundColor(isSelected ? .onBrand : .brand)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .onBrand : .text)
                        .lineLimit(1)
                    
                    if let address = location.address {
                        Text(address)
                            .font(.caption)
                            .foregroundColor(isSelected ? .onBrand.opacity(0.9) : .textSecondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.onBrand)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.brand : Color.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.brand : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Selected Location View
struct SelectedLocationView: View {
    let location: Location
    let onRemove: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Selected Location")
                .font(.headline)
                .foregroundColor(.textSecondary)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.name)
                        .font(.body)
                        .fontWeight(.medium)
                    
                    if let address = location.address {
                        Text(address)
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }
                }
                
                Spacer()
                
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.textSecondary)
                }
            }
            .padding()
            .background(Color.brand.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.brand, lineWidth: 1)
            )
        }
    }
}
