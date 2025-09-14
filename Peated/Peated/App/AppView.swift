import SwiftUI
import UIKit
import PeatedCore

struct AppView: View {
    @State private var model = AppModel()
    @State private var showingDeveloperSettings = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var profileNavigationPath = NavigationPath()
    enum MainTab: Hashable { case activity, search, record, library, profile }
    @State private var selectedTab: MainTab = .activity
    @State private var lastNonRecordTab: MainTab = .activity
    @State private var showingCreateTasting = false
    
    // Navigation destinations for the Profile tab
    enum ProfileDestination: Hashable {
        case userProfile(userId: String)
        case tastingDetail(tastingId: String)
        case bottleDetail(bottleId: String)
                }

    //
    
    // Configure global UIAppearance for consistent chrome/tints
    private func configureAppearance() {
        // Navigation bar
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(Color.chrome)
        // Use concrete UIColors to avoid any UIAppearance/dynamic color bridging quirks
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        // Ensure back chevron and "< Back" text are white, not brand/amber
        UINavigationBar.appearance().tintColor = UIColor(Color.text)

        // Tab bar (selected state may still use brand for affordance)
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(Color.chrome)

        tabAppearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.textMuted)
        tabAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(Color.textMuted)]
        tabAppearance.inlineLayoutAppearance.normal.iconColor = UIColor(Color.textMuted)
        tabAppearance.inlineLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(Color.textMuted)]
        tabAppearance.compactInlineLayoutAppearance.normal.iconColor = UIColor(Color.textMuted)
        tabAppearance.compactInlineLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(Color.textMuted)]

        tabAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.brand)
        tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color.brand)]

        // Slightly increase perceived vertical padding for tab items by
        // nudging title lower relative to icon. This gives more breathing room.
        tabAppearance.stackedLayoutAppearance.normal.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 2)
        tabAppearance.stackedLayoutAppearance.selected.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: 2)
        tabAppearance.inlineLayoutAppearance.selected.iconColor = UIColor(Color.brand)
        tabAppearance.inlineLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color.brand)]
        tabAppearance.compactInlineLayoutAppearance.selected.iconColor = UIColor(Color.brand)
        tabAppearance.compactInlineLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color.brand)]

        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance

        // Refresh control
        UIRefreshControl.appearance().backgroundColor = UIColor(Color.background)
        UIRefreshControl.appearance().tintColor = UIColor(Color.textSecondary)

        // Keep the rest of UIAppearance minimal to avoid UIKit bugs during trait changes.

        // Rely on SwiftUI's preferredColorScheme(.dark) instead of overriding windows
    }

    // Pre-warm assets that commonly flicker (e.g., current user's avatar)
    private func prewarmCurrentUserAssets() {
        if let urlString = AuthenticationManager.shared.currentUser?.pictureUrl,
           let url = URL(string: urlString) {
            ImagePrefetcher.prefetch(urls: [url], max: 1)
        }
    }
    
    var body: some View {
        Group {
            if model.isLoading {
                // Splash screen
                ZStack {
                    ScreenBackground()
                    
                    VStack(spacing: 20) {
                        PeatedLogo(height: 80)
                        
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .brand))
                            .scaleEffect(1.5)
                    }
                }
            } else if model.isAuthenticated {
                // Main app content
                VStack(spacing: 0) {
                    // Offline indicator at the top
                    OfflineIndicator()
                    
                    TabView(selection: $selectedTab) {
                        FeedView()
                            .tabItem {
                                Label("Activity", systemImage: "house.fill")
                            }
                            .tag(MainTab.activity)

                        NavigationStack {
                            SearchView()
                        }
                        .tabItem {
                            Label("Search", systemImage: "magnifyingglass")
                        }
                        .tag(MainTab.search)

                        // Record Tasting middle tab triggers sheet
                        Color.clear
                            .tabItem {
                                Label("Record", systemImage: "plus.circle.fill")
                            }
                            .tag(MainTab.record)

                        NavigationStack {
                            LibraryView()
                        }
                        .tabItem {
                            Label("Library", systemImage: "books.vertical.fill")
                        }
                        .tag(MainTab.library)

                        NavigationStack(path: $profileNavigationPath) {
                            ProfileView(
                                onNavigateToProfile: { userId in
                                    profileNavigationPath.append(ProfileDestination.userProfile(userId: userId))
                                },
                                onNavigateToTasting: { tastingId in
                                    profileNavigationPath.append(ProfileDestination.tastingDetail(tastingId: tastingId))
                                },
                                onNavigateToBottle: { bottleId in
                                    profileNavigationPath.append(ProfileDestination.bottleDetail(bottleId: bottleId))
                                }
                            )
                            .navigationTitle("Profile")
                            .navigationBarTitleDisplayMode(.inline)
                            .navigationDestination(for: ProfileDestination.self) { destination in
                                switch destination {
                                case .userProfile(let userId):
                                    ProfileView(
                                        userId: userId,
                                        onNavigateToProfile: { targetUserId in
                                            profileNavigationPath.append(ProfileDestination.userProfile(userId: targetUserId))
                                        },
                                        onNavigateToTasting: { tastingId in
                                            profileNavigationPath.append(ProfileDestination.tastingDetail(tastingId: tastingId))
                                        },
                                        onNavigateToBottle: { bottleId in
                                            profileNavigationPath.append(ProfileDestination.bottleDetail(bottleId: bottleId))
                                        }
                                    )
                                case .tastingDetail(let tastingId):
                                    TastingDetailView(
                                        tastingId: tastingId,
                                        onNavigateToProfile: { userId in
                                            profileNavigationPath.append(ProfileDestination.userProfile(userId: userId))
                                        },
                                        onNavigateToBottle: { bottleId in
                                            profileNavigationPath.append(ProfileDestination.bottleDetail(bottleId: bottleId))
                                        }
                                    )
                                case .bottleDetail(let bottleId):
                                    BottleDetailView(bottleId: bottleId, bottleName: nil)
                                }
                            }
                        }
                        .tabItem {
                            Label("Profile", systemImage: "person.fill")
                          }
                        .tag(MainTab.profile)
                    }
                    .screenBackground()
                    .onChange(of: selectedTab) { newValue in
                        if newValue == .record {
                            showingCreateTasting = true
                            // revert to last used non-record tab so the modal closes back there
                            selectedTab = lastNonRecordTab
                        } else {
                            lastNonRecordTab = newValue
                        }
                    }
                    .sheet(isPresented: $showingCreateTasting) {
                        CreateTastingFlow(onSuccess: {
                            // Dismiss handled automatically; FeedView will refresh itself when visible
                        })
                        .interactiveDismissDisabled()
                    }
                    .onChange(of: scenePhase) { newPhase in
                        if newPhase == .background {
                            Task { await NormalizedStore.shared.flush() }
                        }
                    }
                }
            } else {
                // Auth flow
                NavigationStack {
                    LoginViewSimple { user in
                        model.handleAuthStateChanged(.authenticated(user))
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .environment(\.colorScheme, .dark)
        .appTheme(ThemeManager.shared.theme) // Provide theme via Environment
        .task {
            await model.checkAuthStatus()
            if model.isAuthenticated { prewarmCurrentUserAssets() }
        }
        .onChange(of: model.isAuthenticated) { newVal in
            if newVal { prewarmCurrentUserAssets() }
        }
        .withToastContainer() // Add toast container at root level
        .onAppear { configureAppearance() } // Ensure appearance is also applied for auth flow
        #if DEBUG
        .onShake {
            showingDeveloperSettings = true
        }
        .sheet(isPresented: $showingDeveloperSettings) {
            DeveloperSettingsView()
        }
        #endif
    }
}
