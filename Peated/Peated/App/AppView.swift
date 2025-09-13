import SwiftUI
import PeatedCore

struct AppView: View {
    @State private var model = AppModel()
    @State private var showingDeveloperSettings = false
    
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
                            Text("Library")
                                .navigationTitle("My Library")
                        }
                        .tabItem {
                            Label("Library", systemImage: "books.vertical.fill")
                        }
                        
                        NavigationStack {
                            ProfileView()
                                .navigationTitle("Profile")
                                .navigationBarTitleDisplayMode(.inline)
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
                        
                        // Inactive state
                        tabAppearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.textSecondary)
                        tabAppearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(Color.textSecondary)]
                        tabAppearance.inlineLayoutAppearance.normal.iconColor = UIColor(Color.textSecondary)
                        tabAppearance.inlineLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(Color.textSecondary)]
                        tabAppearance.compactInlineLayoutAppearance.normal.iconColor = UIColor(Color.textSecondary)
                        tabAppearance.compactInlineLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(Color.textSecondary)]
                        
                        // Active state
                        tabAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.brand)
                        tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color.brand)]
                        tabAppearance.inlineLayoutAppearance.selected.iconColor = UIColor(Color.brand)
                        tabAppearance.inlineLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color.brand)]
                        tabAppearance.compactInlineLayoutAppearance.selected.iconColor = UIColor(Color.brand)
                        tabAppearance.compactInlineLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(Color.brand)]
                        
                        UITabBar.appearance().standardAppearance = tabAppearance
                        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
                        
                        // Customize refresh control appearance
                        UIRefreshControl.appearance().backgroundColor = UIColor(Color.background)
                        UIRefreshControl.appearance().tintColor = UIColor(Color.textSecondary)
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
