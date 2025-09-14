import SwiftUI
import PeatedCore

struct ProfileView: View {
  let userId: String?
  let seed: User?
  let onNavigateToProfile: ((String) -> Void)?
  let onNavigateToTasting: ((String) -> Void)?
  let onNavigateToBottle: ((String) -> Void)?
  
  @State private var model: ProfileModel
  @State private var feedModel = FeedModel()
  @State private var showingLogoutAlert = false
  @State private var selectedTab = 0
  @State private var showingSettings = false
  
  init(
    userId: String? = nil,
    seed: User? = nil,
    onNavigateToProfile: ((String) -> Void)? = nil,
    onNavigateToTasting: ((String) -> Void)? = nil,
    onNavigateToBottle: ((String) -> Void)? = nil
  ) {
    self.userId = userId
    self.seed = seed
    self.onNavigateToProfile = onNavigateToProfile
    self.onNavigateToTasting = onNavigateToTasting
    self.onNavigateToBottle = onNavigateToBottle
    self._model = State(initialValue: ProfileModel(userId: userId, seed: seed))
  }
  
  
  var body: some View {
    content
    .toolbar { toolbarItems }
    .sheet(isPresented: $showingSettings) { SettingsView() }
    .task(id: userId) {
      // Always default to Activity when loading a profile
      selectedTab = 0
      await model.loadUser()
      
      // Only load feed if user loaded successfully
      if model.user != nil {
        // Warm the profile avatar into memory cache to avoid placeholder
        if let s = model.user?.pictureUrl, let u = URL(string: s) {
          ImagePrefetcher.prefetch(urls: [u], max: 1)
        }
        // For the current user, use personal feed
        // For other users, we need to filter the global feed by user (not ideal but API limitation)
        if userId == nil {
          feedModel.selectedFeedType = .personal
        } else {
          // TODO: When API supports filtering by user, update this
          feedModel.selectedFeedType = .global
        }
        // Load from network (personal for self; global fallback for others)
        await feedModel.loadFeed(refresh: true)

        // Preload favorites for this profile
        await model.loadFavorites()

        // Prefetch avatars and bottle images for profile feed
        var urls: [URL] = []
        for item in feedModel.tastings.prefix(40) {
          if let s = item.userAvatarUrl, let u = URL(string: s) { urls.append(u) }
          if let s = item.bottleImageUrl, let u = URL(string: s) { urls.append(u) }
          if let s = item.imageUrl, let u = URL(string: s) { urls.append(u) }
        }
        ImagePrefetcher.prefetch(urls: urls, max: 40)
      }
    }
    .screenBackground()
  }

  @ViewBuilder
  private var content: some View {
    if !model.isPrimed {
      Color.clear.frame(maxWidth: .infinity, maxHeight: .infinity)
    } else if model.error != nil && model.user == nil {
      errorView
    } else {
      loadedView
    }
  }

  @ToolbarContentBuilder
  private var toolbarItems: some ToolbarContent {
    if userId == nil {
      ToolbarItem(placement: .navigationBarTrailing) {
        Button(action: { showingSettings = true }) {
          Image(systemName: "gearshape").foregroundColor(.text)
        }
      }
    } else if let target = model.user, let current = AuthenticationManager.shared.currentUser, target.id != current.id {
      ToolbarItem(placement: .navigationBarTrailing) {
        Menu {
          Button(role: (target.friendStatus == .friends || target.friendStatus == .pending) ? .destructive : .none) {
            Task { await model.toggleFriendship() }
          } label: {
            if target.friendStatus == .friends {
              Label("Unfriend", systemImage: "person.fill.xmark")
            } else if target.friendStatus == .pending {
              Label("Remove Friend", systemImage: "person.fill.xmark")
            } else {
              Label("Add Friend", systemImage: "person.badge.plus")
            }
          }
        } label: {
          if model.isTogglingFriend {
            ProgressView().tint(.brand)
          } else {
            Image(systemName: "ellipsis.circle").foregroundColor(.text)
          }
        }
      }
    }
  }

  // MARK: - Subviews to reduce type-checking complexity
  @ViewBuilder
  private var loadedView: some View {
    ScrollView {
      VStack(spacing: 0) {
        if let _ = model.user {
          profileHeader
        }

        if model.statsPrimed, let _ = model.user {
          statsSection
            .padding(.horizontal)
            .padding(.vertical, 20)
        }

        if !model.achievements.isEmpty {
          badgesSection
            .padding(.bottom, 20)
        }

        // Custom tabs to better match dark chrome and avoid gray segmented look
        HStack(spacing: 0) {
          ForEach([(0, "Activity"), (1, "Favorites")], id: \.0) { pair in
            let idx = pair.0
            let title = pair.1
            Button(action: { selectedTab = idx }) {
              VStack(spacing: 0) {
                Text(title)
                  .font(.system(size: 15, weight: selectedTab == idx ? .medium : .regular))
                  .foregroundColor(selectedTab == idx ? Color.text : Color.textSecondary)
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 12)

                // Bottom indicator
                Rectangle()
                  .fill(selectedTab == idx ? Color.brand : Color.clear)
                  .frame(height: 2)
              }
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .overlay(
          Rectangle()
            .fill(Color.border.opacity(0.2))
            .frame(height: 1),
          alignment: .bottom
        )

        Group {
          if selectedTab == 0 {
            activitySection
          } else {
            favoritesSection
              .padding(.horizontal)
          }
        }
        .onChange(of: selectedTab) { newValue in
          if newValue == 1 {
            Task { await model.loadFavorites() }
          }
        }
      }
    }
    .navigationTitle("Profile")
    .navigationBarTitleDisplayMode(.inline)
    .navigationChrome()
  }

  @ViewBuilder
  private var errorView: some View {
    VStack(spacing: 20) {
      Image(systemName: "exclamationmark.triangle")
        .font(.system(size: 60))
        .foregroundColor(.yellow)

      Text("Unable to load profile")
        .font(.title2)
        .fontWeight(.semibold)

      Text("This user profile could not be loaded.")
        .font(.subheadline)
        .foregroundColor(.textSecondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 40)

      Button(action: { Task { await model.loadUser() } }) {
        Text("Try Again")
          .fontWeight(.medium)
          .foregroundColor(.onBrand)
          .padding(.horizontal, 24)
          .padding(.vertical, 12)
          .background(Color.brand)
          .cornerRadius(25)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .navigationTitle("Profile")
    .navigationBarTitleDisplayMode(.inline)
  }
  
  private var profileHeader: some View {
    VStack(spacing: 16) {
      // Avatar
      if let pictureUrl = model.user?.pictureUrl, !pictureUrl.isEmpty {
        AvatarImage(urlString: pictureUrl, size: 100)
          .task(id: pictureUrl) {
            if let u = URL(string: pictureUrl) {
              ImagePrefetcher.prefetch(urls: [u], max: 1)
            }
          }
      } else {
        // If user not available yet, keep this empty to avoid flicker
        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
          .fill(Color.surface)
          .opacity(0.0)
          .frame(width: 100, height: 100)
      }
      
      // Username and email
      VStack(spacing: 4) {
        if let username = model.user?.username {
          Text(username)
            .font(.system(size: 24, weight: .regular, design: .default))
            .foregroundColor(.text)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
        }
      }
      
      // Role badges
      HStack(spacing: 8) {
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
            .background(Color.danger)
            .foregroundColor(.onStatus)
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
            .background(Color.warning)
            .foregroundColor(.onStatus)
            .cornerRadius(12)
          }
        }
      }
    }
    .padding(.top, 20)
    .padding(.horizontal)
  }
  
  private var statsSection: some View {
    HStack(spacing: 0) {
      StatView(title: "Tastings", value: model.user?.tastingsCount ?? 0)
      Divider()
        .frame(height: 40)
      StatView(title: "Bottles", value: model.user?.bottlesCount ?? 0)
      Divider()
        .frame(height: 40)
      StatView(title: "Collected", value: model.user?.collectedCount ?? 0)
    }
    .padding(.vertical, 16)
    .cornerRadius(12)
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(Color.border.opacity(0.2), lineWidth: 1)
    )
  }
  
  private var badgesSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Achievements")
        .font(.headline)
        .padding(.horizontal)
      
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(alignment: .top, spacing: 12) {
          ForEach(model.achievements) { achievement in
            VStack(spacing: 6) {
              // Badge icon with proper styling
              VStack(spacing: 8) {
                ZStack {
                  RoundedRectangle(cornerRadius: 12)
                    .fill(Color.background)
                    .frame(width: 80, height: 80)
                  
                  // Use imageUrl if available, otherwise fallback to SF Symbol
                  BadgeImage(urlString: achievement.imageUrl, size: 80, cornerRadius: 12)
                }
                
                // Show level instead of name
                Text("Level \(achievement.level)")
                  .font(.caption)
                  .fontWeight(.semibold)
                  .foregroundColor(.primary)
              }
            }
          }
        }
        .padding(.horizontal)
      }
    }
  }
  
  private func achievementIcon(for name: String) -> String {
    switch name.lowercased() {
    case let n where n.contains("malt"):
      return "leaf.fill"
    case let n where n.contains("bourbon"):
      return "flame.fill"
    case let n where n.contains("explorer"):
      return "map.fill"
    default:
      return "medal.fill"
    }
  }
  
  private var activitySection: some View {
    VStack(alignment: .leading, spacing: 8) {
      // Reuse the feed content from FeedView
      if feedModel.isLoading && feedModel.tastings.isEmpty {
        // Loading state
        VStack(spacing: 0) {
          ForEach(0..<3) { index in
            VStack(spacing: 0) {
              SkeletonTastingCard()
              
              if index < 2 {
                Divider()
                  .background(Color.border.opacity(0.2))
              }
            }
          }
        }
        .padding(.horizontal)
      } else if feedModel.error != nil && feedModel.tastings.isEmpty {
        // Error state with no data
        Text("Unable to load activity")
          .foregroundColor(.textSecondary)
          .frame(maxWidth: .infinity, alignment: .center)
          .padding(.vertical, 40)
          .padding(.horizontal)
      } else if feedModel.tastings.isEmpty {
        // Empty state
        Text("No tastings yet")
          .foregroundColor(.textSecondary)
          .frame(maxWidth: .infinity, alignment: .center)
          .padding(.vertical, 40)
          .padding(.horizontal)
      } else {
        // Show tastings using unified feed card design
        VStack(spacing: 0) {
          ActivityList(
            tastings: feedModel.tastings,
            showBottle: true,
            showUserHeader: false,
            limit: 5,
            onToast: { tasting in
              Task { await feedModel.toggleToast(for: tasting.id) }
            },
            onComment: { tasting in
              onNavigateToTasting?(tasting.id)
            },
            onUserTap: { tasting in
              // Don't navigate to self if it's the same user
              if tasting.userId != model.user?.id {
                onNavigateToProfile?(tasting.userId)
              }
            },
            onBottleTap: { tasting in
              onNavigateToTasting?(tasting.id)
            }
          )

          // Show more button if there are more than 5 tastings
          if feedModel.tastings.count > 5 {
            Button(action: {
              // TODO: Navigate to full activity view
            }) {
              Text("View All Activity")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.brand)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
            }
          }
        }
      }
    }
  }
  
  private var favoritesSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Group {
        if model.isLoadingFavorites {
          ProgressView().tint(.brand)
        } else if let err = model.favoritesError {
          VStack(spacing: 8) {
            Text("Couldn't load favorites")
              .font(.subheadline)
            Text(err.localizedDescription)
              .font(.footnote)
              .foregroundColor(.textSecondary)
            Button("Retry") { Task { await model.loadFavorites() } }
              .buttonStyle(.borderedProminent)
          }
          .frame(maxWidth: .infinity)
        } else if model.favorites.isEmpty {
          VStack(spacing: 8) {
            Text("No favorites yet")
              .foregroundColor(.textSecondary)
            Text("Tap the star on a bottle to save it here.")
              .font(.footnote)
              .foregroundColor(.textSecondary)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 24)
        } else {
          ScrollView {
            LazyVStack(spacing: 12) {
              ForEach(model.favorites, id: \.id) { bottle in
                BottleRow(bottle: bottle) {
                  onNavigateToBottle?(bottle.id)
                }
              }
            }
            .padding(.top, 8)
          }
          .refreshable { await model.loadFavorites() }
        }
      }
    }
  }

  struct StatView: View {
    let title: String
    let value: Int
    
    var body: some View {
      VStack(spacing: 4) {
        Text(formatNumber(value))
          .font(.title2)
          .fontWeight(.semibold)
          .foregroundColor(.text)
        Text(title)
          .font(.caption)
          .foregroundColor(.textSecondary)
      }
      .frame(maxWidth: .infinity)
    }

    private func formatNumber(_ number: Int) -> String {
      if number >= 1_000_000 {
        let millions = Double(number) / 1_000_000
        return String(format: "%.1fM", millions)
      } else if number >= 10_000 {
        let thousands = Double(number) / 1_000
        return String(format: "%.0fk", thousands)
      } else if number >= 1_000 {
        let thousands = Double(number) / 1_000
        return String(format: "%.1fk", thousands)
      } else {
        return "\(number)"
      }
    }
  }

}

#Preview {
  ProfileView()
}
