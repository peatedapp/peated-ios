import PeatedCore
import SwiftUI
import UIKit

struct AppView: View {
    @State private var model = AppModel()
    @State private var showingDeveloperSettings = false
    @Environment(\.scenePhase) private var scenePhase
    @State private var profileNavigationPath = NavigationPath()
    enum MainTab: Hashable { case activity, search, record, library, profile }
    @State private var selectedTab: MainTab = .activity
    @State private var lastNonRecordTab: MainTab = .activity
    @State private var showingCreateTasting = false

    /// Tunable tab icon sizing (smaller scale reduces visual crowding)
    private let tabIconScale: UIImage.SymbolScale = .small

    /// Navigation destinations for the Profile tab
    enum ProfileDestination: Hashable {
        case userProfile(userId: String)
        case tastingDetail(tastingId: String)
        case bottleDetail(bottleId: String)
    }

    //

    /// Configure global UIAppearance for consistent chrome/tints
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

        // Tighten icon–label gap and keep the pair visually centered
        // Negative moves the title up, closer to the icon.
        tabAppearance.stackedLayoutAppearance.normal.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -2)
        tabAppearance.stackedLayoutAppearance.selected.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: -2)
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

    /// Helper to produce a tab icon with a desired SF Symbol scale
    private func tabIcon(_ systemName: String) -> Image {
        let config = UIImage.SymbolConfiguration(scale: tabIconScale)
        let uiImage = UIImage(systemName: systemName, withConfiguration: config) ?? UIImage()
        return Image(uiImage: uiImage)
    }

    /// Pre-warm assets that commonly flicker (e.g., current user's avatar)
    private func prewarmCurrentUserAssets() {
        if let urlString = AuthenticationManager.shared.currentUser?.pictureUrl,
           let url = URL(string: urlString)
        {
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
                                Label {
                                    Text("Activity")
                                } icon: {
                                    tabIcon("house.fill")
                                }
                            }
                            .tag(MainTab.activity)

                        NavigationStack {
                            SearchView()
                        }
                        .tabItem {
                            Label {
                                Text("Search")
                            } icon: {
                                tabIcon("magnifyingglass")
                            }
                        }
                        .tag(MainTab.search)

                        // Record Tasting middle tab triggers sheet
                        Color.clear
                            .tabItem {
                                Label {
                                    Text("Record")
                                } icon: {
                                    tabIcon("plus.circle.fill")
                                }
                            }
                            .tag(MainTab.record)

                        NavigationStack {
                            LibraryView()
                        }
                        .tabItem {
                            Label {
                                Text("Library")
                            } icon: {
                                tabIcon("books.vertical.fill")
                            }
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
                                case let .userProfile(userId):
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
                                case let .tastingDetail(tastingId):
                                    TastingDetailView(
                                        tastingId: tastingId,
                                        onNavigateToProfile: { userId in
                                            profileNavigationPath.append(ProfileDestination.userProfile(userId: userId))
                                        },
                                        onNavigateToBottle: { bottleId in
                                            profileNavigationPath.append(ProfileDestination.bottleDetail(bottleId: bottleId))
                                        }
                                    )
                                case let .bottleDetail(bottleId):
                                    BottleDetailView(bottleId: bottleId, bottleName: nil)
                                }
                            }
                        }
                        .tabItem {
                            Label {
                                Text("Profile")
                            } icon: {
                                tabIcon("person.fill")
                            }
                        }
                        .tag(MainTab.profile)
                    }
                    .screenBackground()
                    .onChange(of: selectedTab) { _, newValue in
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
                            // Post notification to refresh feed after tasting creation
                            NotificationCenter.default.post(name: .feedDataRefreshed, object: nil)
                        })
                        .interactiveDismissDisabled()
                    }
                    .onChange(of: scenePhase) { _, newPhase in
                        if newPhase == .background {
                            Task { await NormalizedStore.shared.flush() }
                        }
                    }
                }
                .fullScreenCover(isPresented: Binding(
                    get: { model.needsTermsAcceptance },
                    set: { _ in }
                )) {
                    TermsAcceptanceView {
                        // After accepting, clear the flag and dismiss
                        model.authManager.needsTermsAcceptance = false
                    }
                    .environmentObject(model.authManager)
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
            if model.isAuthenticated {
                prewarmCurrentUserAssets()
            }
            // Prune caches on startup
            await SnapshotStore.pruneAll()
            try? await DatabaseManager.shared.pruneTastingCache(maxEntries: 2000)
            try? await DatabaseManager.shared.pruneTastingCache(olderThanDays: 180)
        }
        .onChange(of: model.isAuthenticated) { _, newVal in
            if newVal {
                prewarmCurrentUserAssets()
            }
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
