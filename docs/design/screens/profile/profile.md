# Profile Screen

## Overview

The Profile screen serves as the user's personal dashboard, showcasing their whisky journey through statistics, achievements, and activity. Based on the production design, it emphasizes visual hierarchy with prominent stats and a clean, scannable layout.

## Visual Layout

```
┌─────────────────────────────────────────┐
│  Profile                           🚪   │
├─────────────────────────────────────────┤
│                                         │
│            [Avatar]                     │
│         @dcramer                        │
│      dcramer@gmail.com                  │
│                                         │
│         [🛡️ Admin]                      │
│                                         │
│  ┌───────┬───────┬───────┬──────────┐  │
│  │  177  │  159  │  28   │   126k   │  │
│  │Tastings│Bottles│Collected│Contributions│
│  └───────┴───────┴───────┴──────────┘  │
│                                         │
│  Achievements                           │
│  ┌─────────────────────────────────┐   │
│  │ 🍃 Single Malter    Level 11    │   │
│  │ 🔥 Bourbon Lover    Level 5     │   │
│  │ 🗺️ Explorer         Level 3     │   │
│  └─────────────────────────────────┘   │
│                                         │
│  [Activity]     [Favorites]             │
│                                         │
│  Recent Activity                        │
│  ┌─────────────────────────────────┐   │
│  │                                 │   │
│  │    No recent activity           │   │
│  │                                 │   │
│  └─────────────────────────────────┘   │
│                                         │
├─────────────────────────────────────────┤
│ [Activity] [Search] [Library] [Profile] │
└─────────────────────────────────────────┘
```

## Implementation Details

### Based on Production Website

The production profile page (peated.com/users/dcramer) revealed key design elements:

1. **User Avatar**: Circular profile photo (when available)
2. **Username Display**: Prominent @username format
3. **Role Badges**: Admin/Mod badges with distinct styling
4. **Statistics Grid**: Four key metrics displayed prominently
5. **Achievements**: Visual badges with levels
6. **Navigation Tabs**: Activity and Favorites sections
7. **Clean Layout**: Dark theme with clear visual hierarchy

### Current Implementation

```swift
import SwiftUI
import PeatedCore

struct ProfileView: View {
    @State private var model = ProfileModel()
    @State private var showingLogoutAlert = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Profile header with avatar
                    profileHeader
                    
                    // Statistics section
                    statsSection
                        .padding(.horizontal)
                        .padding(.vertical, 20)
                    
                    // Achievements badges
                    if !model.achievements.isEmpty {
                        badgesSection
                            .padding(.bottom, 20)
                    }
                    
                    // Activity/Favorites tabs
                    Picker("Content", selection: $selectedTab) {
                        Text("Activity").tag(0)
                        Text("Favorites").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.bottom, 16)
                    
                    // Tab content
                    Group {
                        if selectedTab == 0 {
                            activitySection
                        } else {
                            favoritesSection
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingLogoutAlert = true }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .task {
            await model.loadUser()
        }
    }
}
```

### Key Components

#### Profile Header
```swift
private var profileHeader: some View {
    VStack(spacing: 16) {
        // Avatar with fallback to initials
        if let pictureUrl = model.user?.pictureUrl {
            AsyncImage(url: URL(string: pictureUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(ProgressView())
            }
            .frame(width: 100, height: 100)
            .clipShape(Circle())
        } else {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 100, height: 100)
                .overlay(
                    Text(model.user?.username.prefix(1).uppercased() ?? "?")
                        .font(.largeTitle)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                )
        }
        
        // Username and email
        VStack(spacing: 4) {
            Text("@\(model.user?.username ?? "Loading...")")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(model.user?.email ?? "")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        
        // Role badges (admin supersedes mod)
        if let user = model.user {
            if user.admin {
                HStack(spacing: 4) {
                    Image(systemName: "shield.fill")
                        .font(.caption2)
                    Text("Admin")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(12)
            } else if user.mod {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                    Text("Moderator")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
        }
    }
    .padding(.top, 20)
    .padding(.horizontal)
}
```

#### Statistics Section
```swift
private var statsSection: some View {
    HStack(spacing: 0) {
        StatView(title: "Tastings", value: model.user?.tastingsCount ?? 0)
        Divider().frame(height: 40)
        StatView(title: "Bottles", value: model.user?.bottlesCount ?? 0)
        Divider().frame(height: 40)
        StatView(title: "Collected", value: model.user?.collectedCount ?? 0)
        Divider().frame(height: 40)
        StatView(title: "Contributions", value: model.user?.contributionsCount ?? 0)
    }
    .padding(.vertical, 16)
    .background(Color(.systemGray6))
    .cornerRadius(12)
}

// Number formatting for large values
private func formatNumber(_ number: Int) -> String {
    if number >= 1_000_000 {
        return String(format: "%.1fM", Double(number) / 1_000_000)
    } else if number >= 10_000 {
        return String(format: "%.0fk", Double(number) / 1_000)
    } else if number >= 1_000 {
        return String(format: "%.1fk", Double(number) / 1_000)
    } else {
        return "\(number)"
    }
}
```

#### Achievements Section
```swift
private var badgesSection: some View {
    VStack(alignment: .leading, spacing: 12) {
        Text("Achievements")
            .font(.headline)
            .padding(.horizontal)
        
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(model.achievements) { achievement in
                    VStack(spacing: 6) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.orange.opacity(0.15))
                                .frame(width: 80, height: 80)
                            
                            VStack(spacing: 2) {
                                Image(systemName: achievementIcon(for: achievement.name))
                                    .font(.title)
                                    .foregroundColor(.orange)
                                
                                if achievement.level > 0 {
                                    Text("\(achievement.level)")
                                        .font(.caption2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.orange)
                                }
                            }
                        }
                        
                        Text(achievement.name)
                            .font(.caption)
                            .fontWeight(.medium)
                            .multilineTextAlignment(.center)
                            .frame(width: 80)
                            .lineLimit(2)
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}
```

## API Integration

### User Details Endpoint
The profile fetches additional data from `/users/{user}` which provides:
- Basic user info (id, username, email, admin, mod flags)
- Statistics object with counts (tastings, bottles, collected, contributions)
- Profile picture URL (not currently provided by API)

### Authentication State
Profile data is initially populated from the authentication response, then enriched with the detailed stats from the user details endpoint.

## Features

### Core Information
- **Username**: Displayed with @ prefix
- **Email**: Shown below username for authenticated user
- **Role Badges**: Admin (red) or Moderator (orange)
- **Avatar**: Profile picture with initial fallback

### Statistics
- **Tastings**: Total number of whisky tastings
- **Bottles**: Number of unique bottles tried
- **Collected**: Bottles in collection
- **Contributions**: Total platform contributions
- **Number Formatting**: Large numbers abbreviated (126k instead of 125,909)

### Achievements
- **Visual Badges**: Icons representing achievement types
- **Levels**: Progress indication for each achievement
- **Horizontal Scroll**: Accommodates multiple achievements
- **Dynamic Icons**: Different icons based on achievement name

### Activity Tabs
- **Activity**: Recent tastings and actions (placeholder)
- **Favorites**: Saved items (placeholder)

### Actions
- **Logout**: Red logout icon in navigation bar
- **Pull to Refresh**: Standard iOS gesture support

## State Management

```swift
@Observable
class ProfileModel {
    var user: User?
    var achievements: [Achievement] = []
    var isLoading = false
    var error: Error?
    
    private let authManager = AuthenticationManager.shared
    
    func loadUser() async {
        // Get current user from auth manager
        user = authManager.currentUser
        
        // Load achievements (currently mocked)
        achievements = [
            Achievement(id: "1", name: "Single Malter", level: 11),
            Achievement(id: "2", name: "Bourbon Lover", level: 5),
            Achievement(id: "3", name: "Explorer", level: 3)
        ]
    }
    
    func logout() async {
        isLoading = true
        await authManager.logout()
        isLoading = false
    }
}
```

## Navigation

### To Profile
- Tab bar navigation (Profile tab)
- After successful login
- From other user profiles (future)

### From Profile
- Logout → Returns to login screen
- Activity tab → Shows recent activity
- Favorites tab → Shows saved items

## Design Considerations

### Visual Hierarchy
1. Avatar and username most prominent
2. Statistics clearly visible and scannable
3. Achievements add visual interest
4. Clean separation between sections

### Responsive Layout
- Statistics adapt to different screen sizes
- Achievements scroll horizontally
- Proper spacing and padding throughout

### Dark Theme
- Consistent with platform aesthetic
- Gray backgrounds for depth
- High contrast for readability

## Future Enhancements

### Near Term
- Fetch real achievements from API
- Implement activity feed
- Add favorites functionality
- Profile editing capability

### Long Term
- Top regions and flavors sections
- Social features (following/followers)
- Activity insights and trends
- Profile customization options
- Public profile sharing

## Accessibility

- VoiceOver labels for all interactive elements
- High contrast text on backgrounds
- Semantic grouping of related content
- Standard iOS navigation patterns

## Performance

- Lazy loading of achievements
- Efficient number formatting
- Cached user data from auth
- Minimal API calls