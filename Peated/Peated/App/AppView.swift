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
                    Color.black
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        PeatedLogo(height: 80)
                        
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .peatedGold))
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
                    .tint(.peatedGold)
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
