import SwiftUI
import PeatedCore

struct FeedView: View {
  @State private var model = FeedModel()
  @State private var showingCreateTasting = false
  @State private var navigationPath = NavigationPath()
  
  var body: some View {
    NavigationStack(path: $navigationPath) {
      VStack(spacing: 0) {
        // Feed type picker
        Picker("Feed Type", selection: $model.selectedFeedType) {
          ForEach(FeedType.allCases, id: \.self) { feedType in
            Text(feedType.displayName).tag(feedType)
          }
        }
      .pickerStyle(.segmented)
      .padding(.horizontal)
      .padding(.vertical, 8)
      .onChange(of: model.selectedFeedType) { _, newValue in
        Task {
          await model.switchFeedType(newValue)
        }
      }
      
      // Content container
      ZStack(alignment: .top) {
        // Feed content
        if (model.isLoading || model.isSwitchingFeed) && model.tastings.isEmpty {
          LoadingView()
        } else if model.isErrorWithNoData {
          // Show error-specific empty state
          ErrorEmptyView {
            Task {
              await model.refreshCurrentFeed()
            }
          }
        } else if model.tastings.isEmpty && !model.isLoading && !model.isSwitchingFeed {
          EmptyFeedView(feedType: model.selectedFeedType)
        } else {
          ScrollView {
            LazyVStack(spacing: 0) {
              ForEach(model.tastings) { tasting in
                VStack(spacing: 0) {
                  TastingCard(
                    tasting: tasting,
                    onToast: {
                      Task {
                        await model.toggleToast(for: tasting.id)
                      }
                    },
                    onComment: {
                      // TODO: Navigate to comments
                      print("View comments for: \(tasting.id)")
                    },
                    onUserTap: {
                      // Navigate to user profile
                      print("🧭 Navigating to user profile: \(tasting.userId) (username: \(tasting.username))")
                      navigationPath.append(tasting.userId)
                    },
                    onBottleTap: {
                      // TODO: Navigate to bottle detail
                      print("View bottle: \(tasting.bottleId)")
                    }
                  )
                  
                  // Separator
                  Divider()
                    .background(Color.gray.opacity(0.2))
                }
                .onAppear {
                  Task {
                    await model.loadMoreIfNeeded(currentItem: tasting)
                  }
                }
              }
              
              if model.isLoading && !model.tastings.isEmpty {
                ProgressView()
                  .padding()
              }
            }
          }
          .refreshable {
            await model.refreshCurrentFeed()
          }
        }
        
        // Floating action button
        VStack {
          Spacer()
          HStack {
            Spacer()
            Button(action: { showingCreateTasting = true }) {
              Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.peatedGold)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
            }
            .padding(.trailing, 16)
            .padding(.bottom, 16)
          }
        }
        
        if model.error != nil && model.hasData {
          VStack {
            ErrorBanner(error: model.error!, isShowing: .init(
              get: { model.error != nil },
              set: { _ in model.error = nil }
            ))
            Spacer()
          }
          .animation(.easeInOut, value: model.error != nil)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .navigationTitle("Activity")
    .navigationBarTitleDisplayMode(.inline)
    .sheet(isPresented: $showingCreateTasting) {
      // TODO: Present create tasting flow
      Text("Create Tasting")
    }
    .task {
      await model.loadFeed(refresh: true)
    }
    .navigationDestination(for: String.self) { userId in
      ProfileView(userId: userId)
    }
    }
  }
}

struct LoadingView: View {
  var body: some View {
    ScrollView {
      VStack(spacing: 0) {
        ForEach(0..<5) { index in
          VStack(spacing: 0) {
            SkeletonTastingCard()
            
            if index < 4 {
              Divider()
                .background(Color.gray.opacity(0.2))
            }
          }
        }
      }
    }
  }
}

struct EmptyFeedView: View {
  let feedType: FeedType
  
  var body: some View {
    VStack {
      // Add some top padding
      Spacer().frame(height: 100)
      
      VStack(spacing: 16) {
        Image(systemName: iconName)
          .font(.system(size: 60))
          .foregroundColor(.secondary)
        
        Text(title)
          .font(.title2)
          .fontWeight(.semibold)
        
        Text(message)
          .font(.subheadline)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 40)
        
        if feedType == .friends {
          Button(action: {
            // TODO: Navigate to find friends
          }) {
            Text("Find Friends")
              .fontWeight(.medium)
              .foregroundColor(.white)
              .padding(.horizontal, 24)
              .padding(.vertical, 12)
              .background(Color.peatedGold)
              .cornerRadius(25)
          }
          .padding(.top)
        }
      }
      
      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
  
  private var iconName: String {
    switch feedType {
    case .friends:
      return "person.2"
    case .personal:
      return "wineglass"
    case .global:
      return "globe"
    }
  }
  
  private var title: String {
    switch feedType {
    case .friends:
      return "No Friend Activity"
    case .personal:
      return "No Tastings Yet"
    case .global:
      return "No Global Activity"
    }
  }
  
  private var message: String {
    switch feedType {
    case .friends:
      return "Follow other whisky enthusiasts to see their tastings here"
    case .personal:
      return "Start your whisky journey by creating your first tasting"
    case .global:
      return "Be the first to share a tasting with the community"
    }
  }
}

