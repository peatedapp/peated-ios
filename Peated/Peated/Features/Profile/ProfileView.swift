import PeatedCore
import SwiftUI

// ProfileView predates the current type-size limit; keep this exception scoped to the type.
// swiftlint:disable type_body_length
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
    @State private var activityTastings: [TastingFeedItem] = []
    @State private var activityCursor: String?
    @State private var activityHasMore = true
    @State private var isLoadingActivity = false
    @State private var activityError: Error?

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
        _model = State(initialValue: ProfileModel(userId: userId, seed: seed))
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
                if let user = model.user {
                    // Warm the profile avatar into memory cache to avoid placeholder
                    if let s = user.pictureUrl, let u = URL(string: s) {
                        ImagePrefetcher.prefetch(urls: [u], max: 1)
                    }

                    // Load activity for this specific user
                    await loadActivity(userId: user.id, refresh: true)

                    // Preload the Library for this profile.
                    await model.loadLibrary()

                    // Prefetch avatars and bottle images for profile feed
                    var urls: [URL] = []
                    for item in activityTastings.prefix(40) {
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
                    ImagePrefetcher.prefetch(urls: urls, max: 40)
                }
            }
            .screenBackground()
    }

    @ViewBuilder
    private var content: some View {
        if !model.isPrimed {
            ProfileSkeleton()
        } else if model.error != nil, model.user == nil {
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
        } else if let target = model.user, let current = AuthenticationManager.shared.currentUser,
                  target.id != current.id {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(role: (target.friendStatus == .friends || target.friendStatus == .pending) ? .destructive :
                        .none) {
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

    private var loadedView: some View {
        ScrollView {
            VStack(spacing: 0) {
                if model.user != nil {
                    profileHeader
                }

                if shouldShowVerifyBanner {
                    verifyEmailBanner
                        .padding(.horizontal)
                        .padding(.top, 8)
                }

                if model.statsPrimed, model.user != nil {
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
                    ForEach([(0, "Activity"), (1, "Library")], id: \.0) { pair in
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
                        librarySection
                            .padding(.horizontal)
                    }
                }
                .onChange(of: selectedTab) { _, newValue in
                    if newValue == 1 {
                        Task { await model.loadLibrary() }
                    }
                }
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .navigationChrome()
    }

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

    private var shouldShowVerifyBanner: Bool {
        // Only show banner after profile is fully loaded to avoid flickering
        guard model.isPrimed,
              let current = AuthenticationManager.shared.currentUser,
              let u = model.user else { return false }
        return current.id == u.id && !u.verified
    }

    private var verifyEmailBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "envelope.badge")
                    .foregroundColor(.warning)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Verify your email")
                        .font(.headline)
                        .foregroundColor(.text)
                    Text("Please verify your email to secure your account and enable full features.")
                        .font(.footnote)
                        .foregroundColor(.textSecondary)
                }
                Spacer(minLength: 0)
            }
            HStack {
                Button(action: { Task { await resendVerification() } }) {
                    if isResendingVerification {
                        ProgressView().tint(.onBrand)
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Resend verification email")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.onBrand)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.vertical, 10)
                .background(Color.brand)
                .cornerRadius(10)
            }
        }
        .padding(12)
        .background(Color.surface)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.border.opacity(0.4), lineWidth: 1)
        )
    }

    @State private var isResendingVerification = false
    private func resendVerification() async {
        guard !isResendingVerification else { return }
        isResendingVerification = true
        do {
            try await AuthenticationManager.shared.resendVerificationEmail()
            ToastManager.shared.showSuccess("Verification email sent. Check your inbox.")
        } catch {
            ToastManager.shared.showAPIError(error)
        }
        isResendingVerification = false
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
            "leaf.fill"
        case let n where n.contains("bourbon"):
            "flame.fill"
        case let n where n.contains("explorer"):
            "map.fill"
        default:
            "medal.fill"
        }
    }

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Reuse the feed content from FeedView
            if isLoadingActivity, activityTastings.isEmpty {
                // Loading state
                VStack(spacing: 0) {
                    ForEach(0 ..< 3) { index in
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
            } else if activityError != nil, activityTastings.isEmpty {
                // Error state with no data
                Text("Unable to load activity")
                    .foregroundColor(.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 40)
                    .padding(.horizontal)
            } else if activityTastings.isEmpty {
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
                        tastings: activityTastings,
                        showBottle: true,
                        showUserHeader: false,
                        limit: 5,
                        onToast: { tasting in
                            Task { await toggleActivityToast(for: tasting.id) }
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
                            onNavigateToBottle?(tasting.bottleId)
                        }
                    )

                    // Show more button if there are more than 5 tastings
                    if activityTastings.count > 5 {
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

    private var librarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Group {
                if model.isLoadingLibrary {
                    ProgressView().tint(.brand)
                } else if let err = model.libraryError {
                    VStack(spacing: 8) {
                        Text("Couldn't load library")
                            .font(.subheadline)
                        Text(err.localizedDescription)
                            .font(.footnote)
                            .foregroundColor(.textSecondary)
                        Button("Retry") { Task { await model.loadLibrary() } }
                            .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                } else if model.libraryEntries.isEmpty {
                    VStack(spacing: 8) {
                        Text("No library bottles yet")
                            .foregroundColor(.textSecondary)
                        Text("Save bottles from their detail pages to build a library.")
                            .font(.footnote)
                            .foregroundColor(.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(model.libraryEntries) { entry in
                                BottleRow(bottle: entry.bottle) {
                                    onNavigateToBottle?(entry.bottle.id)
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                    .refreshable { await model.loadLibrary() }
                }
            }
        }
    }

    // MARK: - Activity Loading

    private func loadActivity(userId: String, refresh: Bool = false) async {
        guard !isLoadingActivity else { return }

        isLoadingActivity = true
        activityError = nil

        if refresh {
            activityCursor = nil
            activityHasMore = true
        }

        do {
            let feedRepository = FeedRepository()
            let feedPage = try await feedRepository.getUserTastings(
                userId: userId,
                cursor: activityCursor,
                limit: 20
            )

            if refresh {
                activityTastings = feedPage.tastings
            } else {
                activityTastings.append(contentsOf: feedPage.tastings)
            }

            activityCursor = feedPage.cursor
            activityHasMore = feedPage.hasMore
        } catch {
            activityError = error
        }

        isLoadingActivity = false
    }

    private func toggleActivityToast(for tastingId: String) async {
        // Find the tasting in activity list
        guard let tastingIndex = activityTastings.firstIndex(where: { $0.id == tastingId }) else {
            return
        }

        let currentTasting = activityTastings[tastingIndex]
        let newToastedState = !currentTasting.hasToasted
        let newToastCount = newToastedState ? currentTasting.toastCount + 1 : max(0, currentTasting.toastCount - 1)

        // Create updated tasting for optimistic update
        let updatedTasting = TastingFeedItem(
            id: currentTasting.id,
            ratingBand: currentTasting.ratingBand,
            notes: currentTasting.notes,
            servingStyle: currentTasting.servingStyle,
            imageUrl: currentTasting.imageUrl,
            createdAt: currentTasting.createdAt,
            userId: currentTasting.userId,
            username: currentTasting.username,
            userDisplayName: currentTasting.userDisplayName,
            userAvatarUrl: currentTasting.userAvatarUrl,
            bottleId: currentTasting.bottleId,
            bottleName: currentTasting.bottleName,
            bottleBrandName: currentTasting.bottleBrandName,
            bottleCategory: currentTasting.bottleCategory,
            bottleImageUrl: currentTasting.bottleImageUrl,
            toastCount: newToastCount,
            commentCount: currentTasting.commentCount,
            hasToasted: newToastedState,
            tags: currentTasting.tags,
            location: currentTasting.location,
            friendUsernames: currentTasting.friendUsernames
        )

        // Optimistic update
        activityTastings[tastingIndex] = updatedTasting

        // Perform actual API call
        let tastingRepository = TastingRepository()
        do {
            let actualToastedState = try await tastingRepository.toggleToast(tastingId: tastingId)

            if actualToastedState {
                ToastManager.shared.showSuccess("Cheers! 🥃")
            }

            // Update with correct state from API
            let correctTasting = TastingFeedItem(
                id: currentTasting.id,
                ratingBand: currentTasting.ratingBand,
                notes: currentTasting.notes,
                servingStyle: currentTasting.servingStyle,
                imageUrl: currentTasting.imageUrl,
                createdAt: currentTasting.createdAt,
                userId: currentTasting.userId,
                username: currentTasting.username,
                userDisplayName: currentTasting.userDisplayName,
                userAvatarUrl: currentTasting.userAvatarUrl,
                bottleId: currentTasting.bottleId,
                bottleName: currentTasting.bottleName,
                bottleBrandName: currentTasting.bottleBrandName,
                bottleCategory: currentTasting.bottleCategory,
                bottleImageUrl: currentTasting.bottleImageUrl,
                toastCount: actualToastedState ? currentTasting.toastCount + 1 : max(0, currentTasting.toastCount - 1),
                commentCount: currentTasting.commentCount,
                hasToasted: actualToastedState,
                tags: currentTasting.tags,
                location: currentTasting.location,
                friendUsernames: currentTasting.friendUsernames
            )

            if let currentIndex = activityTastings.firstIndex(where: { $0.id == tastingId }) {
                activityTastings[currentIndex] = correctTasting
            }
        } catch {
            // Revert on error
            if let revertIndex = activityTastings.firstIndex(where: { $0.id == tastingId }) {
                activityTastings[revertIndex] = currentTasting
            }

            if let apiError = error as? APIError,
               case let .requestFailed(message) = apiError,
               message == "Cannot toast this tasting" {
                ToastManager.shared.showError("You can't toast your own tastings")
            } else {
                ToastManager.shared.showError("Failed to update toast")
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
            } else if number >= 10000 {
                let thousands = Double(number) / 1000
                return String(format: "%.0fk", thousands)
            } else if number >= 1000 {
                let thousands = Double(number) / 1000
                return String(format: "%.1fk", thousands)
            } else {
                return "\(number)"
            }
        }
    }
}

// swiftlint:enable type_body_length

#Preview {
    ProfileView()
}
