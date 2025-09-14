import SwiftUI
import PeatedCore

struct AppView: View {
    @State private var model = AppModel()
    @State private var showingDeveloperSettings = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var profileNavigationPath = NavigationPath()
    
    // Navigation destinations for the Profile tab
    enum ProfileDestination: Hashable {
        case userProfile(userId: String)
        case tastingDetail(tastingId: String)
        case bottleDetail(bottleId: String)
    }
    
    var body: some View {
        Group {
            if model.isLoading {
                // Splash screen
                ZStack {
                    Color.background
                        .ignoresSafeArea()
                    
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
                    
                    TabView {
                        FeedView()
                            .tabItem {
                                Label("Activity", systemImage: "house.fill")
                            }
                        
                        NavigationStack {
                            SearchView()
                        }
                        .tabItem {
                            Label("Search", systemImage: "magnifyingglass")
                        }
                        
                        NavigationStack {
                            LibraryView()
                        }
                        .tabItem {
                            Label("Library", systemImage: "books.vertical.fill")
                        }
                        
                        NavigationStack(path: $profileNavigationPath) {
                            ProfileView(
                                onNavigateToProfile: { userId in
                                    profileNavigationPath.append(ProfileDestination.userProfile(userId: userId))
                                },
                                onNavigateToTasting: { tastingId in
                                    profileNavigationPath.append(ProfileDestination.tastingDetail(tastingId: tastingId))
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
                    }
                    .background(Color.background)
                    .tint(.brand)
                    .onAppear {
                        // Customize navigation bar appearance
                        let navAppearance = UINavigationBarAppearance()
                        navAppearance.configureWithOpaqueBackground()
                        navAppearance.backgroundColor = UIColor(Color.background)
                        navAppearance.titleTextAttributes = [.foregroundColor: UIColor(Color.text)]
                        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(Color.text)]
                        
                        UINavigationBar.appearance().standardAppearance = navAppearance
                        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
                        UINavigationBar.appearance().compactAppearance = navAppearance
                        UINavigationBar.appearance().tintColor = UIColor(Color.brand)
                        
                        // Force dark content status bar (dark text on light background)
                        UINavigationBar.appearance().barStyle = .default
                        
                        // Customize tab bar appearance
                        let tabAppearance = UITabBarAppearance()
                        tabAppearance.configureWithOpaqueBackground()
                        tabAppearance.backgroundColor = UIColor(Color.background)
                        
                        // Inactive state (use a muted tone distinct from brand)
                        tabAppearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.textMuted)
                        tabAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(Color.textMuted)]
                        tabAppearance.inlineLayoutAppearance.normal.iconColor = UIColor(Color.textMuted)
                        tabAppearance.inlineLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(Color.textMuted)]
                        tabAppearance.compactInlineLayoutAppearance.normal.iconColor = UIColor(Color.textMuted)
                        tabAppearance.compactInlineLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(Color.textMuted)]
                        
                        // Active state
                        tabAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.brand)
                        tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color.brand)]
                        tabAppearance.inlineLayoutAppearance.selected.iconColor = UIColor(Color.brand)
                        tabAppearance.inlineLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color.brand)]
                        tabAppearance.compactInlineLayoutAppearance.selected.iconColor = UIColor(Color.brand)
                        tabAppearance.compactInlineLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color.brand)]
                        
                        UITabBar.appearance().standardAppearance = tabAppearance
                        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
                        // Ensure SwiftUI respects inactive vs active colors
                        UITabBar.appearance().unselectedItemTintColor = UIColor(Color.textMuted)
                        UITabBar.appearance().tintColor = UIColor(Color.brand)
                        
                        // Customize refresh control appearance
                        UIRefreshControl.appearance().backgroundColor = UIColor(Color.background)
                        UIRefreshControl.appearance().tintColor = UIColor(Color.textSecondary)
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
        .preferredColorScheme(.light)
        .environment(\.colorScheme, .light)
        .appTheme(ThemeManager.shared.theme) // Provide theme via Environment
        .task {
            await model.checkAuthStatus()
        }
        .withToastContainer() // Add toast container at root level
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
