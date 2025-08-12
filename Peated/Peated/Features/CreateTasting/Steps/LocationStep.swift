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
                    
                    Text("Help others discover great spots")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
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
                            .foregroundColor(.secondary)
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
                    .foregroundColor(isSelected ? .black : .accentColor)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("At Home")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .black : .primary)
                    
                    Text("Just chilling")
                        .font(.caption)
                        .foregroundColor(isSelected ? .black.opacity(0.7) : .secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.black)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
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
                            .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "location.fill")
                            .font(.title2)
                            .foregroundColor(isSelected ? .black : .accentColor)
                    }
                }
                .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(currentLocation?.name ?? "Use Current Location")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .black : .primary)
                    
                    if let address = currentLocation?.address {
                        Text(address)
                            .font(.caption)
                            .foregroundColor(isSelected ? .black.opacity(0.7) : .secondary)
                            .lineLimit(2)
                    } else if !isLoading {
                        Text("Tap to find nearby places")
                            .font(.caption)
                            .foregroundColor(isSelected ? .black.opacity(0.7) : .secondary)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.black)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
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
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search for a place...", text: $searchText)
                .textFieldStyle(.plain)
                .focused($isSearchFocused)
                .onSubmit(onSearch)
            
            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
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
                .foregroundColor(.secondary)
            
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
                    .foregroundColor(isSelected ? .black : .accentColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .black : .primary)
                        .lineLimit(1)
                    
                    if let address = location.address {
                        Text(address)
                            .font(.caption)
                            .foregroundColor(isSelected ? .black.opacity(0.7) : .secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.black)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
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
                .foregroundColor(.secondary)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(location.name)
                        .font(.body)
                        .fontWeight(.medium)
                    
                    if let address = location.address {
                        Text(address)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.accentColor, lineWidth: 1)
            )
        }
    }
}