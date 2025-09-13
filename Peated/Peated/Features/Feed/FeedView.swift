import SwiftUI
import PeatedCore

struct FeedView: View {
  @State private var model = FeedModel()
  @State private var showingCreateTasting = false
  @State private var navigationPath = NavigationPath()
  @State private var showingSuccessToast = false
  
  // Navigation destination types
  enum NavigationDestination: Hashable {
    case userProfile(userId: String)
    case tastingDetail(tastingId: String)
    case bottleDetail(bottleId: String)
  }
  
  var body: some View {
    NavigationStack(path: $navigationPath) {
      VStack(spacing: 0) {
        // Tab-style navigation with bottom borders
        HStack(spacing: 0) {
          ForEach(FeedType.allCases, id: \.self) { feedType in
            Button(action: {
              model.selectedFeedType = feedType
              Task {
                await model.switchFeedType(feedType)
              }
            }) {
              VStack(spacing: 0) {
                Text(feedType.displayName)
                  .font(.system(size: 15, weight: model.selectedFeedType == feedType ? .medium : .regular))
                  .foregroundColor(model.selectedFeedType == feedType ? Color.text : Color.textSecondary)
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 12)
                
                // Bottom border indicator
                Rectangle()
                  .fill(model.selectedFeedType == feedType ? Color.brand : Color.clear)
                  .frame(height: 2)
              }
            }
            .buttonStyle(PlainButtonStyle())
          }
        }
        .background(Color.background)
        .overlay(
          // Bottom border for the whole tab bar
          Rectangle()
            .fill(Color.border.opacity(0.2))
            .frame(height: 1),
          alignment: .bottom
        )
      
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
                TastingFeedCard(
                  tasting: tasting,
                  onToast: {
                    Task {
                      await model.toggleToast(for: tasting.id)
                    }
                  },
                  onComment: {
                    // Navigate to tasting detail
                    navigationPath.append(NavigationDestination.tastingDetail(tastingId: tasting.id))
                  },
                  onUserTap: {
                    // Navigate to user profile
                    navigationPath.append(NavigationDestination.userProfile(userId: tasting.userId))
                  },
                  onBottleTap: {
                    // Navigate to tasting detail (not bottle detail)
                    navigationPath.append(NavigationDestination.tastingDetail(tastingId: tasting.id))
                  }
                )
                .background(Color.background)
                .overlay(
                  // Inset light brown separator at the bottom
                  Rectangle()
                    .fill(Color.border)
                    .frame(height: 0.5)
                    .padding(.horizontal, 20),
                  alignment: .bottom
                )
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
            .background(Color.background)
          }
          .scrollContentBackground(.hidden)
          .background(Color.background)
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
                .font(.system(size: 22, weight: .regular))
                .foregroundColor(.onBrand)
                .frame(width: 56, height: 56)
                .background(Color.brand)
                .clipShape(Circle())
                .shadow(color: Color.overlaySoft, radius: 8, x: 0, y: 4)
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
      .background(Color.background)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .navigationTitle("Activity")
      .navigationBarTitleDisplayMode(.inline)
      .toolbarBackground(Color.background, for: .navigationBar)
      .toolbarBackground(.visible, for: .navigationBar)
      .toolbarColorScheme(.light, for: .navigationBar)
      .sheet(isPresented: $showingCreateTasting) {
        CreateTastingFlow(onSuccess: {
          // Show success toast and refresh feed
          showingSuccessToast = true
          Task {
            await model.refreshCurrentFeed()
          }
        })
        .interactiveDismissDisabled()
      }
      .task {
        await model.loadFeed(refresh: true)
      }
      .navigationDestination(for: NavigationDestination.self) { destination in
        switch destination {
        case .userProfile(let userId):
          ProfileView(
            userId: userId,
            onNavigateToProfile: { userId in
              navigationPath.append(NavigationDestination.userProfile(userId: userId))
            },
            onNavigateToTasting: { tastingId in
              navigationPath.append(NavigationDestination.tastingDetail(tastingId: tastingId))
            }
          )
        case .tastingDetail(let tastingId):
          TastingDetailView(
            tastingId: tastingId,
            onNavigateToProfile: { userId in
              navigationPath.append(NavigationDestination.userProfile(userId: userId))
            },
            onNavigateToBottle: { bottleId in
              navigationPath.append(NavigationDestination.bottleDetail(bottleId: bottleId))
            }
          )
        case .bottleDetail(let bottleId):
          BottleDetailView(bottleId: bottleId, bottleName: nil)
        }
      }
    }
    .background(Color.background)
    .toast(
      isShowing: $showingSuccessToast,
      message: "Tasting created successfully!",
      type: .success,
      duration: 3.0
    )
  }
}
}

struct LoadingView: View {
  var body: some View {
    ScrollView {
      LazyVStack(spacing: 0) {
        ForEach(0..<5) { index in
          SkeletonTastingCard()
            .background(Color.background)
            .overlay(
              Rectangle()
                .fill(Color.border)
                .frame(height: 0.5)
                .padding(.horizontal, 20),
              alignment: .bottom
            )
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
          .foregroundColor(.textSecondary)
        
        Text(title)
          .font(.title2)
          .fontWeight(.semibold)
        
        Text(message)
          .font(.subheadline)
          .foregroundColor(.textSecondary)
          .multilineTextAlignment(.center)
          .padding(.horizontal, 40)
        
        if feedType == .friends {
          Button(action: {
            // TODO: Navigate to find friends
          }) {
            Text("Find Friends")
              .fontWeight(.medium)
              .foregroundColor(.onBrand)
              .padding(.horizontal, 24)
              .padding(.vertical, 12)
              .background(Color.brand)
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
