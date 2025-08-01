# Onboarding Flow

## Overview

The onboarding flow introduces new users to Peated's core features through a 3-step carousel. It appears after successful registration and email verification, before the main app experience.

## Visual Layout

### Screen 1: Track Your Journey
```
┌─────────────────────────────────────────┐
│                                   Skip  │
├─────────────────────────────────────────┤
│                                         │
│         [Whisky Library Icon]           │
│              📚🥃                      │
│                                         │
│         Track Your Journey              │
│                                         │
│    Build your personal whisky library   │
│    Rate and remember every dram         │
│    See your tasting history             │
│                                         │
│         ●  ○  ○                         │
│                                         │
│    ┌─────────────────────────────┐     │
│    │           Next              │     │
│    └─────────────────────────────┘     │
│                                         │
└─────────────────────────────────────────┘
```

### Screen 2: Share Your Taste
```
┌─────────────────────────────────────────┐
│                                   Skip  │
├─────────────────────────────────────────┤
│                                         │
│         [Social Toasting Icon]          │
│              🥃🥃                      │
│                                         │
│         Share Your Taste                │
│                                         │
│    Connect with fellow whisky lovers    │
│    Toast and comment on tastings        │
│    Follow friends and experts           │
│                                         │
│         ○  ●  ○                         │
│                                         │
│    ┌─────────────────────────────┐     │
│    │           Next              │     │
│    └─────────────────────────────┘     │
│                                         │
└─────────────────────────────────────────┘
```

### Screen 3: Discover New Favorites
```
┌─────────────────────────────────────────┐
│                                   Skip  │
├─────────────────────────────────────────┤
│                                         │
│         [Search/Discover Icon]          │
│              🔍🥃                      │
│                                         │
│       Discover New Favorites            │
│                                         │
│    Explore thousands of whiskies        │
│    Get personalized recommendations     │
│    Find the perfect dram                │
│                                         │
│         ○  ○  ●                         │
│                                         │
│    ┌─────────────────────────────┐     │
│    │        Get Started          │     │
│    └─────────────────────────────┘     │
│                                         │
└─────────────────────────────────────────┘
```

### Permissions Screen
```
┌─────────────────────────────────────────┐
│        Enable Key Features              │
├─────────────────────────────────────────┤
│                                         │
│    To get the most from Peated:        │
│                                         │
│    📷 Camera                            │
│    Scan bottle barcodes and add photos │
│    ┌─────────────────────────────┐     │
│    │         Enable              │     │
│    └─────────────────────────────┘     │
│                                         │
│    🔔 Notifications                     │
│    Get toasts and comments             │
│    ┌─────────────────────────────┐     │
│    │         Enable              │     │
│    └─────────────────────────────┘     │
│                                         │
│    📍 Location (Optional)               │
│    Tag where you're drinking           │
│    ┌─────────────────────────────┐     │
│    │      Maybe Later            │     │
│    └─────────────────────────────┘     │
│                                         │
│    ┌─────────────────────────────┐     │
│    │         Continue            │     │
│    └─────────────────────────────┘     │
│                                         │
└─────────────────────────────────────────┘
```

## Implementation

```swift
import SwiftUI
import AVFoundation
import CoreLocation
import UserNotifications

struct OnboardingFlow: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage = 0
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.showPermissions {
                PermissionsView(viewModel: viewModel)
                    .transition(.move(edge: .trailing))
            } else {
                OnboardingPager(currentPage: $currentPage, viewModel: viewModel)
                    .transition(.move(edge: .leading))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: viewModel.showPermissions)
    }
}

// MARK: - Onboarding Pager
struct OnboardingPager: View {
    @Binding var currentPage: Int
    @ObservedObject var viewModel: OnboardingViewModel
    
    var body: some View {
        VStack {
            // Skip button
            HStack {
                Spacer()
                Button("Skip") {
                    viewModel.showPermissions = true
                }
                .foregroundColor(.secondary)
                .padding()
            }
            
            // Content
            TabView(selection: $currentPage) {
                OnboardingPage(
                    icon: "📚🥃",
                    title: "Track Your Journey",
                    features: [
                        "Build your personal whisky library",
                        "Rate and remember every dram",
                        "See your tasting history"
                    ],
                    action: {
                        withAnimation {
                            currentPage = 1
                        }
                    },
                    actionTitle: "Next"
                )
                .tag(0)
                
                OnboardingPage(
                    icon: "🥃🥃",
                    title: "Share Your Taste",
                    features: [
                        "Connect with fellow whisky lovers",
                        "Toast and comment on tastings",
                        "Follow friends and experts"
                    ],
                    action: {
                        withAnimation {
                            currentPage = 2
                        }
                    },
                    actionTitle: "Next"
                )
                .tag(1)
                
                OnboardingPage(
                    icon: "🔍🥃",
                    title: "Discover New Favorites",
                    features: [
                        "Explore thousands of whiskies",
                        "Get personalized recommendations",
                        "Find the perfect dram"
                    ],
                    action: {
                        viewModel.showPermissions = true
                    },
                    actionTitle: "Get Started"
                )
                .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // Page indicators
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(currentPage == index ? Color.accentColor : Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                        .animation(.easeInOut, value: currentPage)
                }
            }
            .padding(.bottom, 20)
        }
    }
}

// MARK: - Onboarding Page
struct OnboardingPage: View {
    let icon: String
    let title: String
    let features: [String]
    let action: () -> Void
    let actionTitle: String
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon
            Text(icon)
                .font(.system(size: 80))
                .scaleEffect(1.0)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.6)
                        .repeatCount(1, autoreverses: true),
                    value: icon
                )
            
            // Title
            Text(title)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            // Features
            VStack(alignment: .leading, spacing: 16) {
                ForEach(features, id: \.self) { feature in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                        
                        Text(feature)
                            .font(.body)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Action button
            Button(action: action) {
                Text(actionTitle)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor)
                    .cornerRadius(25)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Permissions View
struct PermissionsView: View {
    @ObservedObject var viewModel: OnboardingViewModel
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            Text("Enable Key Features")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 60)
            
            Text("To get the most from Peated:")
                .font(.body)
                .foregroundColor(.secondary)
            
            VStack(spacing: 20) {
                // Camera permission
                PermissionRow(
                    icon: "camera.fill",
                    title: "Camera",
                    description: "Scan bottle barcodes and add photos",
                    status: viewModel.cameraStatus,
                    action: {
                        viewModel.requestCameraPermission()
                    }
                )
                
                // Notifications permission
                PermissionRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    description: "Get toasts and comments",
                    status: viewModel.notificationStatus,
                    action: {
                        viewModel.requestNotificationPermission()
                    }
                )
                
                // Location permission (optional)
                PermissionRow(
                    icon: "location.fill",
                    title: "Location (Optional)",
                    description: "Tag where you're drinking",
                    status: viewModel.locationStatus,
                    action: {
                        viewModel.requestLocationPermission()
                    },
                    isOptional: true
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 40)
            
            Spacer()
            
            // Continue button
            Button(action: {
                hasCompletedOnboarding = true
            }) {
                Text("Continue")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor)
                    .cornerRadius(25)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Permission Row
struct PermissionRow: View {
    let icon: String
    let title: String
    let description: String
    let status: PermissionStatus
    let action: () -> Void
    var isOptional: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Button(action: action) {
                Text(buttonTitle)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(buttonForegroundColor)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(buttonBackgroundColor)
                    .cornerRadius(20)
            }
            .disabled(status == .granted)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    private var buttonTitle: String {
        switch status {
        case .notDetermined:
            return isOptional ? "Maybe Later" : "Enable"
        case .granted:
            return "Enabled"
        case .denied:
            return "Open Settings"
        }
    }
    
    private var buttonForegroundColor: Color {
        switch status {
        case .granted:
            return .white
        case .denied:
            return .accentColor
        default:
            return isOptional ? .secondary : .white
        }
    }
    
    private var buttonBackgroundColor: Color {
        switch status {
        case .granted:
            return .green
        case .denied:
            return Color(.secondarySystemBackground)
        default:
            return isOptional ? Color(.tertiarySystemBackground) : .accentColor
        }
    }
}

// MARK: - View Model
enum PermissionStatus {
    case notDetermined
    case granted
    case denied
}

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var showPermissions = false
    @Published var cameraStatus: PermissionStatus = .notDetermined
    @Published var notificationStatus: PermissionStatus = .notDetermined
    @Published var locationStatus: PermissionStatus = .notDetermined
    
    init() {
        checkPermissionStatuses()
    }
    
    private func checkPermissionStatuses() {
        // Camera
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraStatus = .granted
        case .denied, .restricted:
            cameraStatus = .denied
        default:
            cameraStatus = .notDetermined
        }
        
        // Notifications
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .authorized:
                    self.notificationStatus = .granted
                case .denied:
                    self.notificationStatus = .denied
                default:
                    self.notificationStatus = .notDetermined
                }
            }
        }
        
        // Location
        let locationStatus = CLLocationManager.authorizationStatus()
        switch locationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            self.locationStatus = .granted
        case .denied, .restricted:
            self.locationStatus = .denied
        default:
            self.locationStatus = .notDetermined
        }
    }
    
    func requestCameraPermission() {
        if cameraStatus == .denied {
            openSettings()
            return
        }
        
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                self.cameraStatus = granted ? .granted : .denied
            }
        }
    }
    
    func requestNotificationPermission() {
        if notificationStatus == .denied {
            openSettings()
            return
        }
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            DispatchQueue.main.async {
                self.notificationStatus = granted ? .granted : .denied
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    func requestLocationPermission() {
        if locationStatus == .denied {
            openSettings()
            return
        }
        
        let locationManager = CLLocationManager()
        locationManager.requestWhenInUseAuthorization()
        
        // Status will update via delegate
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.checkPermissionStatuses()
        }
    }
    
    private func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}
```

## Navigation

### Entry Points
- First successful login after registration
- Can be triggered manually from settings

### Exit Points
- Complete all steps → Main app
- Skip → Permissions → Main app

## Permissions Strategy

### Required Permissions
- **Camera**: For barcode scanning and photos
- **Notifications**: For social interactions

### Optional Permissions
- **Location**: For venue check-ins
- **Photo Library**: Requested when needed

## Best Practices

1. **Progressive Disclosure**: Don't overwhelm with all features
2. **Value Proposition**: Explain why each permission is needed
3. **Skip Option**: Let users explore first
4. **Re-engagement**: Can request permissions later when relevant

## Analytics Events

- `onboarding_started`
- `onboarding_page_viewed` (page number)
- `onboarding_skipped` (at which page)
- `permission_requested` (type, result)
- `onboarding_completed`

## Accessibility

- Full VoiceOver support
- Keyboard navigation
- High contrast mode support
- Reduced motion respected

## Testing Scenarios

1. Complete flow without skipping
2. Skip at each stage
3. Deny all permissions
4. Mixed permission states
5. Return from settings
6. Landscape orientation handling