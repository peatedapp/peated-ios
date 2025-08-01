# Profile Screen

## Overview

The Profile screen serves as the user's personal dashboard, showcasing their whisky journey through statistics, achievements, recent activity, and social connections. It also provides access to settings and account management.

## Visual Layout

```
┌─────────────────────────────────────────┐
│  Profile                           ⚙️   │
├─────────────────────────────────────────┤
│                                         │
│       [Avatar]                          │
│    John Smith                           │
│    @johnsmith                           │
│                                         │
│  ┌─────────────┬─────────────────┐     │
│  │  Following  │    Followers     │     │
│  │     127     │       89         │     │
│  └─────────────┴─────────────────┘     │
│                                         │
│  "Exploring the world of whisky,        │
│   one dram at a time 🥃"               │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │        Edit Profile             │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ─────────────────────────────────      │
│                                         │
│  Statistics                             │
│  ┌───────┬───────┬───────┬───────┐     │
│  │  234  │  89   │  4.2  │  12   │     │
│  │Tastings│Unique│  Avg  │Countries│    │
│  └───────┴───────┴───────┴───────┘     │
│                                         │
│  Achievements                    See All│
│  ┌─────────────────────────────────┐   │
│  │ 🏆 Century Club (100 tastings)  │   │
│  │ 🌍 World Explorer (5 countries) │   │
│  │ 🔥 30 Day Streak                │   │
│  └─────────────────────────────────┘   │
│                                         │
│  Recent Activity                        │
│  ┌─────────────────────────────────┐   │
│  │ [Tasting] Ardbeg 10 ★★★★☆       │   │
│  │ [Tasting] Lagavulin 16 ★★★★★    │   │
│  │ [Achievement] Islay Explorer 🏆  │   │
│  └─────────────────────────────────┘   │
│                                         │
├─────────────────────────────────────────┤
│ [Feed] [Search] [Library] [Profile]     │
└─────────────────────────────────────────┘
```

### Settings Screen
```
┌─────────────────────────────────────────┐
│  ← Profile         Settings             │
├─────────────────────────────────────────┤
│                                         │
│  Account                                │
│  ┌─────────────────────────────────┐   │
│  │ Profile Information          >  │   │
│  │ Email & Password             >  │   │
│  │ Privacy Settings             >  │   │
│  │ Blocked Users               >  │   │
│  └─────────────────────────────────┘   │
│                                         │
│  Preferences                            │
│  ┌─────────────────────────────────┐   │
│  │ Notifications                >  │   │
│  │ Units (Metric/Imperial)      >  │   │
│  │ Default Privacy              >  │   │
│  │ Data Usage                   >  │   │
│  └─────────────────────────────────┘   │
│                                         │
│  About                                  │
│  ┌─────────────────────────────────┐   │
│  │ Help & Support              >  │   │
│  │ Terms of Service            >  │   │
│  │ Privacy Policy              >  │   │
│  │ Version 1.0.0                  │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │         Sign Out               │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │     Delete Account             │   │
│  └─────────────────────────────────┘   │
│                                         │
└─────────────────────────────────────────┘
```

## Implementation

```swift
import SwiftUI

struct ProfileScreen: View {
    @State private var model = ProfileModel()
    @State private var showingSettings = false
    @State private var showingEditProfile = false
    @State private var selectedTab = 0
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile header
                    profileHeader
                    
                    // Social stats
                    socialStats
                    
                    // Bio
                    if let bio = model.user?.bio, !bio.isEmpty {
                        biSection(bio)
                    }
                    
                    // Edit profile button
                    editProfileButton
                    
                    Divider()
                        .padding(.horizontal)
                    
                    // Statistics
                    statisticsSection
                    
                    // Achievements
                    achievementsSection
                    
                    // Recent activity
                    recentActivitySection
                }
                .padding(.vertical)
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                NavigationView {
                    SettingsScreen()
                }
            }
            .sheet(isPresented: $showingEditProfile) {
                NavigationView {
                    EditProfileView(user: model.user ?? User.placeholder)
                }
            }
            .task {
                await model.loadProfile()
            }
            .refreshable {
                await model.refresh()
            }
        }
    }
    
    // MARK: - Profile Header
    @ViewBuilder
    private var profileHeader: some View {
        VStack(spacing: 12) {
            // Avatar
            UserAvatar(
                user: model.user,
                size: 100,
                showsEditOverlay: true,
                onEdit: {
                    showingEditProfile = true
                }
            )
            
            // Name
            Text(model.user?.displayName ?? model.user?.username ?? "")
                .font(.title2)
                .fontWeight(.bold)
            
            // Username
            Text("@\(model.user?.username ?? "")")
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Social Stats
    @ViewBuilder
    private var socialStats: some View {
        HStack(spacing: 0) {
            NavigationLink(destination: FollowingListView(userId: model.user?.id ?? "")) {
                VStack(spacing: 4) {
                    Text("Following")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(model.followingCount)")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            
            Divider()
                .frame(height: 40)
            
            NavigationLink(destination: FollowersListView(userId: model.user?.id ?? "")) {
                VStack(spacing: 4) {
                    Text("Followers")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(model.followersCount)")
                        .font(.title3)
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    // MARK: - Bio Section
    @ViewBuilder
    private func biSection(_ bio: String) -> some View {
        Text(bio)
            .font(.body)
            .multilineTextAlignment(.center)
            .padding(.horizontal)
    }
    
    // MARK: - Edit Profile Button
    @ViewBuilder
    private var editProfileButton: some View {
        Button(action: { showingEditProfile = true }) {
            Text("Edit Profile")
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Statistics Section
    @ViewBuilder
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Statistics")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink(destination: DetailedStatsView()) {
                    Text("Details")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    StatCard(
                        value: "\(model.stats.totalTastings)",
                        label: "Tastings",
                        icon: "checkmark.circle.fill",
                        color: .blue
                    )
                    
                    StatCard(
                        value: "\(model.stats.uniqueBottles)",
                        label: "Unique",
                        icon: "square.grid.2x2.fill",
                        color: .green
                    )
                    
                    StatCard(
                        value: String(format: "%.1f", model.stats.averageRating),
                        label: "Avg Rating",
                        icon: "star.fill",
                        color: .yellow
                    )
                    
                    StatCard(
                        value: "\(model.stats.countriesCount)",
                        label: "Countries",
                        icon: "globe",
                        color: .purple
                    )
                    
                    StatCard(
                        value: "\(model.stats.currentStreak)",
                        label: "Day Streak",
                        icon: "flame.fill",
                        color: .orange
                    )
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Achievements Section
    @ViewBuilder
    private var achievementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Achievements")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink(destination: AchievementsView()) {
                    Text("See All")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal)
            
            if model.recentAchievements.isEmpty {
                EmptyStateCard(
                    icon: "trophy",
                    message: "No achievements yet",
                    action: "Start tasting to earn achievements"
                )
                .padding(.horizontal)
            } else {
                VStack(spacing: 12) {
                    ForEach(model.recentAchievements.prefix(3)) { achievement in
                        AchievementRow(achievement: achievement)
                    }
                }
                .padding(.horizontal)
            }
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
                
                NavigationLink(destination: ActivityHistoryView()) {
                    Text("View All")
                        .font(.caption)
                        .foregroundColor(.accentColor)
                }
            }
            .padding(.horizontal)
            
            if model.recentActivity.isEmpty {
                EmptyStateCard(
                    icon: "clock",
                    message: "No recent activity",
                    action: "Add your first tasting"
                )
                .padding(.horizontal)
            } else {
                VStack(spacing: 0) {
                    ForEach(model.recentActivity.prefix(5)) { activity in
                        ActivityRow(activity: activity)
                        
                        if activity != model.recentActivity.prefix(5).last {
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

// MARK: - Stat Card
struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 100, height: 100)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Achievement Row
struct AchievementRow: View {
    let achievement: Achievement
    
    var body: some View {
        HStack(spacing: 12) {
            Text(achievement.emoji)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(achievement.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if achievement.isNew {
                Text("NEW")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.red)
                    .cornerRadius(4)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Activity Row
struct ActivityRow: View {
    let activity: UserActivity
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon based on activity type
            Image(systemName: activity.icon)
                .font(.title3)
                .foregroundColor(activity.iconColor)
                .frame(width: 32, height: 32)
                .background(activity.iconColor.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.body)
                    .lineLimit(1)
                
                Text(activity.timestamp.relativeTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let rating = activity.rating {
                HStack(spacing: 2) {
                    RatingView(rating: rating, size: 12)
                }
            }
        }
        .padding()
    }
}

// MARK: - Settings Screen
struct SettingsScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    @State private var showingSignOutAlert = false
    @State private var showingDeleteAccountAlert = false
    
    var body: some View {
        List {
            // Account Section
            Section("Account") {
                NavigationLink(destination: ProfileInformationView()) {
                    Label("Profile Information", systemImage: "person.circle")
                }
                
                NavigationLink(destination: EmailPasswordView()) {
                    Label("Email & Password", systemImage: "envelope")
                }
                
                NavigationLink(destination: PrivacySettingsView()) {
                    Label("Privacy Settings", systemImage: "lock")
                }
                
                NavigationLink(destination: BlockedUsersView()) {
                    Label("Blocked Users", systemImage: "person.2.slash")
                }
            }
            
            // Preferences Section
            Section("Preferences") {
                NavigationLink(destination: NotificationSettingsView()) {
                    Label("Notifications", systemImage: "bell")
                }
                
                NavigationLink(destination: UnitsSettingsView()) {
                    Label("Units", systemImage: "ruler")
                }
                
                NavigationLink(destination: DefaultPrivacyView()) {
                    Label("Default Privacy", systemImage: "eye")
                }
                
                NavigationLink(destination: DataUsageView()) {
                    Label("Data Usage", systemImage: "arrow.up.arrow.down")
                }
            }
            
            // About Section
            Section("About") {
                NavigationLink(destination: HelpSupportView()) {
                    Label("Help & Support", systemImage: "questionmark.circle")
                }
                
                NavigationLink(destination: TermsOfServiceView()) {
                    Label("Terms of Service", systemImage: "doc.text")
                }
                
                NavigationLink(destination: PrivacyPolicyView()) {
                    Label("Privacy Policy", systemImage: "hand.raised")
                }
                
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.appVersion)
                        .foregroundColor(.secondary)
                }
            }
            
            // Actions Section
            Section {
                Button(action: { showingSignOutAlert = true }) {
                    HStack {
                        Spacer()
                        Text("Sign Out")
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
                
                Button(action: { showingDeleteAccountAlert = true }) {
                    HStack {
                        Spacer()
                        Text("Delete Account")
                            .foregroundColor(.red)
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authManager.signOut()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await deleteAccount()
                }
            }
        } message: {
            Text("This will permanently delete your account and all associated data. This action cannot be undone.")
        }
    }
    
    private func deleteAccount() async {
        // Implement account deletion
    }
}

// MARK: - Model
@Observable
class ProfileModel {
    var user: User?
    var stats = UserStatistics()
    var followingCount = 0
    var followersCount = 0
    var recentAchievements: [Achievement] = []
    var recentActivity: [UserActivity] = []
    var isLoading = false
    
    struct UserStatistics {
        var totalTastings: Int = 0
        var uniqueBottles: Int = 0
        var averageRating: Double = 0.0
        var countriesCount: Int = 0
        var currentStreak: Int = 0
        var longestStreak: Int = 0
        var favoriteCategory: String?
        var favoriteDistillery: String?
    }
    
    func loadProfile() async {
        isLoading = true
        
        // Load user data
        // Load statistics
        // Load achievements
        // Load recent activity
        
        // Mock data
        stats = UserStatistics(
            totalTastings: 234,
            uniqueBottles: 89,
            averageRating: 4.2,
            countriesCount: 12,
            currentStreak: 7,
            longestStreak: 30
        )
        
        followingCount = 127
        followersCount = 89
        
        recentAchievements = [
            Achievement(
                id: "1",
                name: "Century Club",
                description: "100 tastings completed",
                emoji: "🏆",
                unlockedAt: Date(),
                isNew: true
            ),
            Achievement(
                id: "2",
                name: "World Explorer",
                description: "Tried whiskies from 5 countries",
                emoji: "🌍",
                unlockedAt: Date().addingTimeInterval(-86400),
                isNew: false
            )
        ]
        
        isLoading = false
    }
    
    func refresh() async {
        await loadProfile()
    }
}

// MARK: - Models
struct Achievement: Identifiable {
    let id: String
    let name: String
    let description: String
    let emoji: String
    let unlockedAt: Date
    let isNew: Bool
}

struct UserActivity: Identifiable {
    let id: String
    let type: ActivityType
    let title: String
    let timestamp: Date
    let rating: Double?
    
    enum ActivityType {
        case tasting
        case achievement
        case follow
        case milestone
    }
    
    var icon: String {
        switch type {
        case .tasting: return "wineglass"
        case .achievement: return "trophy"
        case .follow: return "person.badge.plus"
        case .milestone: return "flag.checkered"
        }
    }
    
    var iconColor: Color {
        switch type {
        case .tasting: return .blue
        case .achievement: return .yellow
        case .follow: return .green
        case .milestone: return .purple
        }
    }
}
```

## Features

### Profile Information
- **Avatar**: Editable profile photo
- **Display Name**: Full name display
- **Username**: Unique identifier
- **Bio**: Personal description
- **Social Stats**: Following/followers with navigation

### Statistics Dashboard
- **Core Metrics**: Tastings, unique bottles, average rating
- **Geographic**: Countries explored
- **Streaks**: Current and longest
- **Detailed View**: Deep analytics

### Achievements System
- **Recent Unlocks**: Latest 3 achievements
- **Visual Badges**: Emoji representation
- **Progress Tracking**: Partial completion
- **Categories**: Various achievement types
- **New Indicators**: Highlight recent unlocks

### Activity Timeline
- **Recent Tastings**: Latest check-ins
- **Achievements**: Newly unlocked
- **Milestones**: Significant events
- **Social**: Following updates

### Settings Organization

#### Account Management
- **Profile Information**: Edit name, username, bio
- **Email & Password**: Security updates
- **Privacy Settings**: Visibility controls
- **Blocked Users**: Manage blocks

#### Preferences
- **Notifications**: Push and email settings
- **Units**: Metric/Imperial
- **Default Privacy**: New tasting defaults
- **Data Usage**: Cellular/WiFi settings

#### About & Support
- **Help**: FAQs and support
- **Terms**: Legal documents
- **Version**: App information

## Navigation

### From Profile
- Settings → Full settings menu
- Edit Profile → Profile editor
- Following/Followers → User lists
- Statistics → Detailed analytics
- Achievements → Full list
- Activity → Complete history

### To Profile
- Tab bar navigation
- After editing profile
- From other user profiles

## State Management

### Profile Data
- User information cached
- Real-time stat updates
- Achievement notifications
- Activity feed pagination

### Settings Persistence
- UserDefaults for preferences
- Keychain for sensitive data
- CloudKit sync (future)

## User Experience

### Visual Design
- Clean card layouts
- Clear information hierarchy
- Consistent spacing
- Platform conventions

### Interactions
- Pull-to-refresh
- Smooth transitions
- Loading states
- Error handling

### Empty States
- No achievements yet
- No recent activity
- Helpful CTAs

## Privacy & Security

### Account Actions
- Sign out confirmation
- Account deletion warning
- Data export option
- Privacy controls

### Data Protection
- Secure credential storage
- Privacy by default
- Clear data policies

## Accessibility

- VoiceOver optimized
- Dynamic Type support
- High contrast mode
- Reduced motion respected

## Future Enhancements

- Profile themes/customization
- Public profile sharing
- Achievement sharing
- Activity insights
- Export data options
- Badge collections