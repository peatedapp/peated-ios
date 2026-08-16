import PeatedCore
import SwiftUI

struct SearchView: View {
    @State private var model = SearchModel()
    @FocusState private var focused: Bool
    @State private var navigationPath = NavigationPath()

    struct BottleSeed: Hashable {
        let id: String
        let name: String
        let fullName: String
        let brandId: String
        let brandName: String
        let category: String?
        let imageUrl: String?
        let isFavorite: Bool
        let isLibrary: Bool
        let hasTasted: Bool
    }

    struct EntitySeed: Hashable { let id: String; let name: String; let type: Entity.EntityType }
    struct UserSeed: Hashable { let id: String; let username: String; let pictureUrl: String? }

    enum SearchDestination: Hashable {
        case bottleDetail(seed: BottleSeed)
        case entityDetail(seed: EntitySeed)
        case userProfile(seed: UserSeed)
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                searchBar
                    .padding(.horizontal)
                    .padding(.vertical, 8)

                content
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .animation(.easeInOut(duration: 0.2), value: model.isSearching)
            .navigationBarHidden(true)
            .navigationChrome()
            .navigationDestination(for: SearchDestination.self) { destination in
                switch destination {
                case let .bottleDetail(seed):
                    let bottle = Bottle(
                        id: seed.id,
                        name: seed.name,
                        fullName: seed.fullName,
                        brand: Brand(id: seed.brandId, name: seed.brandName),
                        category: seed.category,
                        imageUrl: seed.imageUrl,
                        isFavorite: seed.isFavorite,
                        isLibrary: seed.isLibrary,
                        hasTasted: seed.hasTasted
                    )
                    BottleDetailView(
                        bottleId: seed.id,
                        bottleName: seed.fullName,
                        seed: bottle,
                        navigationPath: $navigationPath
                    )
                case let .entityDetail(seed):
                    let entity = Entity(id: seed.id, name: seed.name, type: seed.type)
                    EntityDetailView(
                        entityId: seed.id,
                        entityName: seed.name,
                        seed: entity,
                        navigationPath: $navigationPath
                    )
                case let .userProfile(seed):
                    let user = User(id: seed.id, email: "", username: seed.username).withPicture(seed.pictureUrl)
                    ProfileView(
                        userId: seed.id,
                        seed: user,
                        onNavigateToProfile: { userId in
                            navigationPath.append(SearchDestination.userProfile(seed: UserSeed(
                                id: userId,
                                username: "",
                                pictureUrl: nil
                            )))
                        },
                        onNavigateToTasting: { tastingId in
                            navigationPath.append(TastingActivityNavigationDestination.tasting(
                                id: tastingId,
                                seed: nil
                            ))
                        },
                        onNavigateToBottle: { bottleId in
                            navigationPath.append(SearchDestination.bottleDetail(seed: BottleSeed(
                                id: bottleId, name: "", fullName: "", brandId: "", brandName: "", category: nil,
                                imageUrl: nil, isFavorite: false, isLibrary: false, hasTasted: false
                            )))
                        }
                    )
                }
            }
            .tastingActivityNavigationDestinations(path: $navigationPath)
        }
        .screenBackground()
        .onChange(of: model.friendshipErrorMessage) { _, message in
            guard let message else { return }
            ToastManager.shared.showError(message)
            model.friendshipErrorMessage = nil
        }
    }
}

extension SearchView {
    private var searchBar: some View {
        HStack(spacing: 12) {
            SearchInput(placeholder: "Search bottles, brands, users", text: $model.searchText, onSubmit: {
                model.submit()
            })
            .onChange(of: model.searchText) { _, newValue in
                model.onChange(query: newValue)
            }

            if model.isSearching {
                Button("Cancel") {
                    model.searchText = ""
                    focused = false
                    model.isSearching = false
                    model.clear()
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .onChange(of: focused) { _, isFocused in
            withAnimation { model.isSearching = isFocused }
        }
    }

    @ViewBuilder
    private var content: some View {
        if model.searchText.isEmpty {
            defaultView
        } else {
            resultsView
        }
    }

    private var defaultView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if !model.recentSearches.isEmpty {
                    recentSection
                }

                if !model.popularBottles.isEmpty {
                    popularBottlesSection
                }

                if !model.topRatedBottles.isEmpty {
                    topRatedBottlesSection
                }
            }
            .padding(.vertical)
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Searches").font(.headline)
                Spacer()
                Button("Clear") { model.clearAllRecent() }
                    .font(.caption)
                    .foregroundColor(.brand)
            }
            .padding(.horizontal)

            VStack(spacing: 0) {
                ForEach(model.recentSearches, id: \.self) { query in
                    Button {
                        model.searchText = query
                        model.onChange(query: query)
                    } label: {
                        HStack(alignment: .center, spacing: 12) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.caption)
                                .foregroundColor(.textSecondary)

                            Text(query)
                                .foregroundColor(.text)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Button(action: { model.removeRecent(query) }) {
                                Image(systemName: "xmark")
                                    .font(.caption)
                                    .foregroundColor(.textSecondary)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                    if query != model.recentSearches.last {
                        Divider().padding(.leading, 44)
                    }
                }
            }
            .background(Color.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.border.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var resultsView: some View {
        switch model.state {
        case .idle:
            EmptyView()
        case .loading:
            loadingView
        case let .results(results):
            if results.isEmpty {
                noResultsView
            } else {
                resultsList(results)
            }
        case let .error(message):
            errorView(message)
        }
    }

    private func resultsList(_ results: [SearchResult]) -> some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Group results by type
                let groupedResults = Dictionary(grouping: results) { $0.type }

                // Show sections in order: bottles, entities, users
                ForEach(SearchResultType.allCases, id: \.self) { type in
                    if let typeResults = groupedResults[type], !typeResults.isEmpty {
                        resultSection(type: type, results: typeResults)
                    }
                }
            }
            .padding(.vertical)
        }
    }

    private func resultSection(type: SearchResultType, results: [SearchResult]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(type.sectionTitle)
                .font(.headline)
                .foregroundColor(.textSecondary)
                .padding(.horizontal)

            VStack(spacing: 0) {
                ForEach(results) { result in
                    if result.type == .user {
                        userResultRow(result)
                    } else {
                        Button(action: { handleTap(result) }, label: {
                            resultRow(result)
                        })
                        .buttonStyle(.plain)
                    }
                    if result.id != results.last?.id {
                        Divider().padding(.leading, 60)
                    }
                }
            }
            .background(Color.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.border.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    private func resultRow(_ result: SearchResult) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Simple placeholder iconography for now
            Group {
                switch result.type {
                case .bottle:
                    if let bottle = result.bottle {
                        // Reuse app-wide bottle presentation
                        BottleImage(imageUrl: bottle.imageUrl)
                            .frame(
                                width: DesignSystem.ImageSize.bottleThumb.width,
                                height: DesignSystem.ImageSize.bottleThumb.height
                            )
                    } else {
                        Image(systemName: "wineglass").font(.title2).foregroundColor(.textSecondary)
                            .frame(width: 44, height: 44)
                            .background(Color.surfaceSubtle)
                            .cornerRadius(8)
                    }
                case .entity:
                    Image(systemName: "building.2").font(.title2).foregroundColor(.textSecondary)
                        .frame(width: 44, height: 44)
                        .background(Color.surfaceSubtle)
                        .cornerRadius(8)
                case .user:
                    Image(systemName: "person.crop.circle").font(.title2).foregroundColor(.textSecondary)
                        .frame(width: 44, height: 44)
                }
            }

            if result.type == .bottle, let bottle = result.bottle {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxSmall) {
                    Text(bottle.fullName)
                        .font(.system(size: DesignSystem.FontSize.title, weight: .semibold, design: .default))
                        .foregroundColor(.text)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: DesignSystem.Spacing.xSmall) {
                        Text(bottle.brandName)
                            .font(.system(size: DesignSystem.FontSize.body))
                            .foregroundColor(.textSecondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        if let category = bottle.category {
                            Text("•").foregroundColor(.textMuted)
                            Text(category.replacingOccurrences(of: "_", with: " ").capitalized)
                                .font(.system(size: DesignSystem.FontSize.body))
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
                Spacer(minLength: DesignSystem.Spacing.small)
                // Compact status icons: tasted + Library
                if let bottle = result.bottle {
                    HStack(spacing: 6) {
                        if bottle.hasTasted {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)
                        }
                        if bottle.isLibrary {
                            Image(systemName: "books.vertical.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
                Image(systemName: "chevron.right").font(.caption).foregroundColor(.textSecondary)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.name).font(.body).foregroundColor(.text)
                    if let subtitle = result.subtitle, !subtitle.isEmpty {
                        Text(subtitle).font(.subheadline).foregroundColor(.textSecondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption).foregroundColor(.textSecondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    private func userResultRow(_ result: SearchResult) -> some View {
        HStack(spacing: 12) {
            Button(action: { handleTap(result) }, label: {
                HStack(spacing: 12) {
                    AvatarImage(urlString: result.imageUrl, size: 44)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(result.name)
                            .font(.body)
                            .foregroundColor(.text)
                        if let subtitle = result.subtitle, !subtitle.isEmpty {
                            Text(subtitle)
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                        }
                    }

                    Spacer()
                }
                .contentShape(Rectangle())
            })
            .buttonStyle(.plain)

            if result.id == AuthenticationManager.shared.currentUser?.id {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            } else if model.updatingFriendIds.contains(result.id) {
                ProgressView()
                    .tint(.brand)
                    .frame(width: 72)
                    .accessibilityLabel("Updating friendship")
            } else {
                Button(friendshipButtonTitle(for: result)) {
                    Task { await model.toggleFriendship(for: result) }
                }
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(friendshipButtonForegroundColor(for: result))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(friendshipButtonBackground(for: result))
                .clipShape(Capsule())
                .buttonStyle(.plain)
                .accessibilityLabel(friendshipAccessibilityLabel(for: result))
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    private func friendshipButtonTitle(for result: SearchResult) -> String {
        switch result.friendStatus ?? .none {
        case .none: "Add Friend"
        case .pending: "Request Pending"
        case .friends: "Remove Friend"
        }
    }

    private func friendshipButtonBackground(for result: SearchResult) -> Color {
        switch result.friendStatus ?? .none {
        case .none: Color.brand.opacity(0.1)
        case .pending, .friends: Color.surfaceSubtle
        }
    }

    private func friendshipButtonForegroundColor(for result: SearchResult) -> Color {
        switch result.friendStatus ?? .none {
        case .none: .brand
        case .pending, .friends: .textSecondary
        }
    }

    private func friendshipAccessibilityLabel(for result: SearchResult) -> String {
        switch result.friendStatus ?? .none {
        case .none: "Follow \(result.name)"
        case .pending: "Cancel friend request to \(result.name)"
        case .friends: "Unfollow \(result.name)"
        }
    }

    private var loadingView: some View {
        SearchResultsSkeleton()
    }

    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass").font(.system(size: 50)).foregroundColor(.textSecondary)
            Text("No results for \"\(model.searchText)\"").font(.title3).fontWeight(.semibold)
            Text("Try searching for something else").font(.body).foregroundColor(.textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle").foregroundColor(.warning)
            Text("Search failed").font(.headline)
            Text(message).font(.footnote).foregroundColor(.textSecondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var popularBottlesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Popular Bottles")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 0) {
                ForEach(model.popularBottles) { bottle in
                    Button(action: { handleBottleTap(bottle) }) {
                        bottleRow(bottle)
                    }
                    .buttonStyle(.plain)
                    if bottle.id != model.popularBottles.last?.id {
                        Divider().padding(.leading, 60)
                    }
                }
            }
            .background(Color.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.border.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    private var topRatedBottlesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Rated")
                .font(.headline)
                .padding(.horizontal)

            VStack(spacing: 0) {
                ForEach(model.topRatedBottles) { bottle in
                    Button(action: { handleBottleTap(bottle) }) {
                        bottleRow(bottle)
                    }
                    .buttonStyle(.plain)
                    if bottle.id != model.topRatedBottles.last?.id {
                        Divider().padding(.leading, 60)
                    }
                }
            }
            .background(Color.surface)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.border.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    private func bottleRow(_ bottle: Bottle) -> some View {
        HStack(spacing: 12) {
            BottleImage(imageUrl: bottle.imageUrl)
                .frame(
                    width: DesignSystem.ImageSize.bottleThumb.width,
                    height: DesignSystem.ImageSize.bottleThumb.height
                )

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxSmall) {
                Text(bottle.fullName)
                    .font(.system(size: DesignSystem.FontSize.body, weight: .medium))
                    .foregroundColor(.text)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: DesignSystem.Spacing.xSmall) {
                    if let category = bottle.category {
                        Text(category.replacingOccurrences(of: "_", with: " ").capitalized)
                            .font(.system(size: DesignSystem.FontSize.small))
                            .foregroundColor(.textSecondary)
                    }

                    if bottle.totalRatings > 0 {
                        Text("•").foregroundColor(.textMuted)
                        CommunityRatingView(
                            average: bottle.avgRating,
                            total: bottle.totalRatings,
                            showCount: false
                        )
                    }
                }
            }

            Spacer()

            // Compact status icons: tasted + Library
            HStack(spacing: 6) {
                if bottle.hasTasted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.textSecondary)
                }
                if bottle.isLibrary {
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.textSecondary)
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }

    private func handleTap(_ result: SearchResult) {
        model.addRecent(result.name)

        switch result.type {
        case .bottle:
            if let b = result.bottle {
                let s = BottleSeed(
                    id: b.id,
                    name: b.name,
                    fullName: b.fullName,
                    brandId: b.brand.id,
                    brandName: b.brand.name,
                    category: b.category,
                    imageUrl: b.imageUrl,
                    isFavorite: b.isFavorite,
                    isLibrary: b.isLibrary,
                    hasTasted: b.hasTasted
                )
                navigationPath.append(SearchDestination.bottleDetail(seed: s))
            } else {
                // Minimal seed when API doesn’t return full object in result
                let s = BottleSeed(
                    id: result.id,
                    name: result.name,
                    fullName: result.name,
                    brandId: "0",
                    brandName: "",
                    category: nil,
                    imageUrl: nil,
                    isFavorite: false,
                    isLibrary: false,
                    hasTasted: false
                )
                navigationPath.append(SearchDestination.bottleDetail(seed: s))
            }
        case .entity:
            let e = EntitySeed(id: result.id, name: result.name, type: .brand)
            navigationPath.append(SearchDestination.entityDetail(seed: e))
        case .user:
            let userSeed = UserSeed(id: result.id, username: result.name, pictureUrl: result.imageUrl)
            navigationPath.append(SearchDestination.userProfile(seed: userSeed))
        }
    }

    private func handleBottleTap(_ bottle: Bottle) {
        model.addRecent(bottle.fullName)
        let s = BottleSeed(
            id: bottle.id,
            name: bottle.name,
            fullName: bottle.fullName,
            brandId: bottle.brand.id,
            brandName: bottle.brand.name,
            category: bottle.category,
            imageUrl: bottle.imageUrl,
            isFavorite: bottle.isFavorite,
            isLibrary: bottle.isLibrary,
            hasTasted: bottle.hasTasted
        )
        navigationPath.append(SearchDestination.bottleDetail(seed: s))
    }
}
