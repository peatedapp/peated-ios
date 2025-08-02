import SwiftUI

struct AppView: View {
    @State private var model = AppModel()
    
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
                TabView {
                    NavigationStack {
                        FeedView()
                    }
                    .tabItem {
                        Label("Activity", systemImage: "house.fill")
                    }
                    
                    NavigationStack {
                        Text("Search")
                            .navigationTitle("Search")
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
                    
                    ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person.fill")
                    }
                }
                .tint(.peatedGold)
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
    }
}

