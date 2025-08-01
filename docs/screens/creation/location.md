# Location Step

## Overview

The third step of the tasting creation flow allows users to specify where they're enjoying their whisky and who they're with. This includes venue check-ins (future), friend tagging, and a quick "at home" option.

## Visual Layout

```
┌─────────────────────────────────────────┐
│  ✕ Cancel          Check In (3/5)       │
├─────────────────────────────────────────┤
│                                         │
│  Where are you enjoying this?           │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │     🏠 Drinking at Home         │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ 📍 Search for a location...     │   │
│  └─────────────────────────────────┘   │
│  (Coming soon)                          │
│                                         │
│  ─────────────────────────────────      │
│                                         │
│  Who are you with? (Optional)           │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ 👥 Tag friends...               │   │
│  └─────────────────────────────────┘   │
│                                         │
│  Tagged Friends:                        │
│  ┌─────────────────────────────────┐   │
│  │ [Avatar] Sarah M.            ✕  │   │
│  │ [Avatar] Mike Chen           ✕  │   │
│  └─────────────────────────────────┘   │
│                                         │
├─────────────────────────────────────────┤
│  ← Back                    Continue →   │
└─────────────────────────────────────────┘
```

### Friend Search Active
```
┌─────────────────────────────────────────┐
│  Tag Friends                       Done │
├─────────────────────────────────────────┤
│  ┌─────────────────────────────────┐   │
│  │ 🔍 Search friends...            │   │
│  └─────────────────────────────────┘   │
│                                         │
│  Following                              │
│  ┌─────────────────────────────────┐   │
│  │ [Avatar] John Smith          [+] │   │
│  │         @johnsmith               │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ [Avatar] Sarah Miller     [✓]   │   │
│  │         @sarahmiller             │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ [Avatar] Mike Chen        [✓]   │   │
│  │         @mikechen                │   │
│  └─────────────────────────────────┘   │
│                                         │
└─────────────────────────────────────────┘
```

## Implementation

```swift
import SwiftUI
import CoreLocation

struct LocationStep: View {
    @ObservedObject var viewModel: CreateTastingViewModel
    @State private var showingFriendPicker = false
    @State private var locationSearchText = ""
    @State private var friendSearchText = ""
    @State private var availableFriends: [User] = []
    @StateObject private var locationManager = LocationManager()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                Text("Where are you enjoying this?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                    .padding(.top)
                
                // Location section
                locationSection
                
                Divider()
                    .padding(.horizontal)
                
                // Friends section
                friendsSection
                
                // Add padding for navigation buttons
                Color.clear.frame(height: 100)
            }
        }
        .sheet(isPresented: $showingFriendPicker) {
            FriendPickerView(
                selectedFriends: $viewModel.taggedFriends,
                availableFriends: availableFriends
            )
        }
        .task {
            await loadFollowingList()
        }
    }
    
    // MARK: - Location Section
    @ViewBuilder
    private var locationSection: some View {
        VStack(spacing: 12) {
            // Drinking at home button
            Button(action: {
                toggleDrinkingAtHome()
            }) {
                HStack {
                    Image(systemName: "house.fill")
                        .font(.title3)
                        .foregroundColor(viewModel.isDrinkingAtHome ? .white : .accentColor)
                    
                    Text("Drinking at Home")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(viewModel.isDrinkingAtHome ? .white : .primary)
                    
                    Spacer()
                    
                    if viewModel.isDrinkingAtHome {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(viewModel.isDrinkingAtHome ? Color.accentColor : Color(.secondarySystemBackground))
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            
            // Location search (placeholder for now)
            VStack(alignment: .leading, spacing: 8) {
                Button(action: {
                    // Future: Show location search
                }) {
                    HStack {
                        Image(systemName: "mappin.circle")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        Text("Search for a location...")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.tertiarySystemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.separator), lineWidth: 1)
                                    .strokeStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                            )
                    )
                }
                .buttonStyle(.plain)
                .disabled(true)
                
                Text("Location check-ins coming soon")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
            .padding(.horizontal)
            .opacity(viewModel.isDrinkingAtHome ? 0.5 : 1.0)
            .disabled(viewModel.isDrinkingAtHome)
            
            // Current location suggestion (future)
            if locationManager.authorizationStatus == .authorizedWhenInUse && !viewModel.isDrinkingAtHome {
                currentLocationSuggestion
            }
        }
    }
    
    // MARK: - Friends Section
    @ViewBuilder
    private var friendsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Who are you with?")
                    .font(.headline)
                
                Text("(Optional)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            // Tag friends button
            Button(action: {
                showingFriendPicker = true
            }) {
                HStack {
                    Image(systemName: "person.2.fill")
                        .font(.title3)
                        .foregroundColor(.accentColor)
                    
                    Text(viewModel.taggedFriends.isEmpty ? "Tag friends..." : "Add more friends...")
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if !viewModel.taggedFriends.isEmpty {
                        Text("\(viewModel.taggedFriends.count)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor)
                            .clipShape(Capsule())
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            
            // Tagged friends list
            if !viewModel.taggedFriends.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tagged Friends:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    VStack(spacing: 0) {
                        ForEach(viewModel.taggedFriends) { friend in
                            HStack {
                                UserAvatar(user: friend, size: 40)
                                
                                VStack(alignment: .leading) {
                                    Text(friend.displayName ?? friend.username)
                                        .font(.body)
                                        .fontWeight(.medium)
                                    
                                    Text("@\(friend.username)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button(action: {
                                    removeTaggedFriend(friend)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            
                            if friend != viewModel.taggedFriends.last {
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
        }
    }
    
    // MARK: - Current Location Suggestion
    @ViewBuilder
    private var currentLocationSuggestion: some View {
        if let currentLocation = locationManager.currentLocation {
            VStack(alignment: .leading, spacing: 8) {
                Text("Near you:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Placeholder for nearby venues
                Text("Location features coming soon")
                    .font(.caption)
                    .italic()
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Actions
    private func toggleDrinkingAtHome() {
        withAnimation {
            viewModel.isDrinkingAtHome.toggle()
            if viewModel.isDrinkingAtHome {
                viewModel.selectedLocation = nil
            }
        }
        
        // Haptic feedback
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    private func removeTaggedFriend(_ friend: User) {
        withAnimation {
            viewModel.taggedFriends.removeAll { $0.id == friend.id }
        }
    }
    
    private func loadFollowingList() async {
        // Load user's following list for friend picker
        // Mock data for now
        availableFriends = []
    }
}

// MARK: - Friend Picker View
struct FriendPickerView: View {
    @Binding var selectedFriends: [User]
    let availableFriends: [User]
    @State private var searchText = ""
    @State private var filteredFriends: [User] = []
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search friends...", text: $searchText)
                        .textFieldStyle(.plain)
                        .onChange(of: searchText) { _ in
                            filterFriends()
                        }
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .padding()
                
                // Friends list
                if filteredFriends.isEmpty && !searchText.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        
                        Text("No friends found")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        Section {
                            ForEach(filteredFriends.isEmpty ? availableFriends : filteredFriends) { friend in
                                FriendRow(
                                    friend: friend,
                                    isSelected: selectedFriends.contains { $0.id == friend.id },
                                    onToggle: {
                                        toggleFriend(friend)
                                    }
                                )
                            }
                        } header: {
                            Text("Following")
                                .font(.headline)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Tag Friends")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.medium)
                }
            }
        }
        .onAppear {
            filteredFriends = availableFriends
        }
    }
    
    private func filterFriends() {
        if searchText.isEmpty {
            filteredFriends = availableFriends
        } else {
            filteredFriends = availableFriends.filter { friend in
                friend.username.localizedCaseInsensitiveContains(searchText) ||
                (friend.displayName?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    private func toggleFriend(_ friend: User) {
        withAnimation {
            if selectedFriends.contains(where: { $0.id == friend.id }) {
                selectedFriends.removeAll { $0.id == friend.id }
            } else {
                selectedFriends.append(friend)
            }
        }
        
        // Haptic feedback
        UISelectionFeedbackGenerator().selectionChanged()
    }
}

// MARK: - Friend Row
struct FriendRow: View {
    let friend: User
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                UserAvatar(user: friend, size: 44)
                
                VStack(alignment: .leading) {
                    Text(friend.displayName ?? friend.username)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text("@\(friend.username)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .font(.title3)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Location Manager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func getCurrentLocation() {
        locationManager.requestLocation()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error)")
    }
}
```

## Features

### Location Options

#### Drinking at Home
- Quick toggle button
- Prominent placement
- Disables venue search when selected
- Visual confirmation state

#### Venue Search (Future)
- Placeholder UI for now
- Disabled state with "coming soon" message
- Dashed border to indicate future feature
- Will support:
  - Search by name
  - Nearby venues
  - Recent locations
  - Popular venues

### Friend Tagging

#### Tag Friends Button
- Shows count badge when friends selected
- Opens full-screen picker
- Clear call-to-action

#### Friend Picker
- Search within following list
- Real-time filtering
- Multiple selection
- Visual selection state
- Done button to confirm

#### Tagged Friends Display
- Avatar and name
- Username handle
- Remove button (×)
- Clean list layout

### Location Permissions (Future)
- Will request when needed
- Show nearby venues
- "Near you" suggestions
- Privacy-conscious

## State Management

### Location State
- `isDrinkingAtHome` toggle
- `selectedLocation` for venues (future)
- Mutually exclusive states

### Friends State
- `taggedFriends` array
- Persists through navigation
- No limit on selections

## User Experience

### Visual Hierarchy
1. Drinking at home - Primary option
2. Location search - Secondary (disabled)
3. Friend tagging - Social element

### Interactions
- Toggle animations
- Haptic feedback
- Smooth transitions
- Clear disabled states

### Empty States
- No friends to tag
- Search with no results
- Helpful messages

## Navigation

### Friend Picker
- Modal presentation
- Search functionality
- Done to dismiss
- Changes saved immediately

### Step Navigation
- Back preserves all selections
- Continue always enabled (all optional)
- Data persists through flow

## Future Enhancements

### Venue Check-ins
- Search by name/category
- GPS-based suggestions
- Recent venues
- Popular venues
- Create new venue

### Location Features
- Map view
- Distance from current location
- Venue details (hours, type)
- Check-in history

### Social Features
- See who else checked in
- Venue leaderboards
- Location-based recommendations

## Accessibility

- VoiceOver support for all controls
- Location permission explanation
- Friend selection announced
- Clear labeling

## Performance

- Lazy load friend list
- Efficient search filtering
- Minimal location updates
- Smooth animations