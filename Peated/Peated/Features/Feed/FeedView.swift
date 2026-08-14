import PeatedCore
import SwiftUI

struct FeedView: View {
    @State private var model = FeedModel()
    @State private var navigationPath = NavigationPath()
    @State private var showingSuccessToast = false

    private func prefetchFeedImages() {
        var urls: [URL] = []
        for item in model.tastings.prefix(60) {
            if let s = item.userAvatarUrl, let u = URL(string: s) {
                urls.append(u)
            }
            if let s = item.bottleImageUrl, let u = URL(string: s) {
                urls.append(u)
            }
            if let s = item.imageUrl, let u = URL(string: s) {
                urls.append(u)
            }
        }
        ImagePrefetcher.prefetch(urls: urls, max: 60)
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
                                    .font(.system(
                                        size: 15,
                                        weight: model.selectedFeedType == feedType ? .medium : .regular
                                    ))
                                    .foregroundColor(model.selectedFeedType == feedType ? Color.text : Color
                                        .textSecondary)
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
                    if model.isLoading || model.isSwitchingFeed, model.tastings.isEmpty {
                        LoadingView()
                    } else if model.isErrorWithNoData {
                        // Show error-specific empty state
                        ErrorEmptyView {
                            Task {
                                await model.refreshCurrentFeed()
                            }
                        }
                    } else if model.tastings.isEmpty, !model.isLoading, !model.isSwitchingFeed {
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
                                            navigationPath.append(
                                                TastingActivityNavigationDestination.tasting(
                                                    id: tasting.id,
                                                    seed: tasting
                                                )
                                            )
                                        },
                                        onUserTap: {
                                            navigationPath.append(
                                                TastingActivityNavigationDestination.profile(
                                                    id: tasting.userId,
                                                    username: tasting.username,
                                                    pictureUrl: tasting.userAvatarUrl
                                                )
                                            )
                                        },
                                        onBottleTap: {
                                            navigationPath.append(
                                                TastingActivityNavigationDestination.bottle(id: tasting.bottleId)
                                            )
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

                                if model.isLoading, !model.tastings.isEmpty {
                                    ProgressView()
                                        .padding()
                                }
                            }
                        }
                        .scrollContentBackground(.hidden)
                        .refreshable {
                            await model.refreshCurrentFeed()
                        }
                    }

                    if model.error != nil, model.hasData {
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
                .navigationBarHidden(true)
                // Record Tasting now lives on center tab in AppView
                .task {
                    await model.loadFeed(refresh: true)
                    prefetchFeedImages()
                }
                .tastingActivityNavigationDestinations(path: $navigationPath)
            }
            .screenBackground()
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
                ForEach(0 ..< 5) { _ in
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
            "person.2"
        case .personal:
            "wineglass"
        case .global:
            "globe"
        }
    }

    private var title: String {
        switch feedType {
        case .friends:
            "No Friend Activity"
        case .personal:
            "No Tastings Yet"
        case .global:
            "No Global Activity"
        }
    }

    private var message: String {
        switch feedType {
        case .friends:
            "Follow other whisky enthusiasts to see their tastings here"
        case .personal:
            "Start your whisky journey by creating your first tasting"
        case .global:
            "Be the first to share a tasting with the community"
        }
    }
}
