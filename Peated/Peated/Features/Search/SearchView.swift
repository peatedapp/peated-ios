import SwiftUI
import PeatedCore
import Observation

@Observable
final class SearchModel {
  var searchText: String = ""
  var isSearching: Bool = false
  var recentSearches: [String] = []
  var state: State = .idle
  var popularBottles: [Bottle] = []
  var topRatedBottles: [Bottle] = []

  enum State: Equatable {
    case idle
    case loading
    case results([SearchResult])
    case error(String)
  }

  private let repository: SearchRepository
  private let bottleRepository: BottleRepository
  private var task: Task<Void, Never>?

  init(repository: SearchRepository = SearchRepository(), bottleRepository: BottleRepository = BottleRepository()) {
    self.repository = repository
    self.bottleRepository = bottleRepository
    loadRecent()
    loadPopularContent()
  }

  func onChange(query: String) {
    task?.cancel()
    let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      state = .idle
      return
    }
    state = .loading
    task = Task { [weak self] in
      do {
        try await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce
        guard !Task.isCancelled else { return }
        let results = try await self?.repository.search(query: trimmed, limit: 50) ?? []
        guard !Task.isCancelled else { return }
        self?.state = .results(results)
      } catch {
        guard !Task.isCancelled else { return }
        self?.state = .error(error.localizedDescription)
      }
    }
  }

  func submit() {
    let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !q.isEmpty else { return }
    addRecent(q)
  }

  func clear() {
    task?.cancel()
    state = .idle
  }

  // MARK: Recent
  private func loadRecent() {
    recentSearches = UserDefaults.standard.stringArray(forKey: "recentSearches") ?? []
  }

  private func persistRecent() {
    UserDefaults.standard.set(recentSearches, forKey: "recentSearches")
  }

  func addRecent(_ query: String) {
    var list = recentSearches
    list.removeAll { $0.caseInsensitiveCompare(query) == .orderedSame }
    list.insert(query, at: 0)
    if list.count > 10 { list = Array(list.prefix(10)) }
    recentSearches = list
    persistRecent()
  }

  func removeRecent(_ query: String) {
    recentSearches.removeAll { $0 == query }
    persistRecent()
  }

  func clearAllRecent() {
    recentSearches = []
    persistRecent()
  }
  
  private func loadPopularContent() {
    Task {
      do {
        async let popular = bottleRepository.getPopularBottles(limit: 5)
        async let topRated = bottleRepository.getTopRatedBottles(limit: 5)
        
        popularBottles = try await popular
        topRatedBottles = try await topRated
      } catch {
        // Silently fail for non-critical content
        print("Failed to load popular content: \(error)")
      }
    }
  }
}

struct SearchView: View {
  @State private var model = SearchModel()
  @FocusState private var focused: Bool
  @State private var navigationPath = NavigationPath()
  
  struct BottleSeed: Hashable { let id: String; let name: String; let fullName: String; let brandId: String; let brandName: String; let category: String?; let imageUrl: String?; let isFavorite: Bool; let hasTasted: Bool }
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
        case .bottleDetail(let seed):
          let bottle = Bottle(
            id: seed.id,
            name: seed.name,
            fullName: seed.fullName,
            brand: Brand(id: seed.brandId, name: seed.brandName),
            category: seed.category,
            imageUrl: seed.imageUrl,
            isFavorite: seed.isFavorite,
            hasTasted: seed.hasTasted
          )
          BottleDetailView(bottleId: seed.id, bottleName: seed.fullName, seed: bottle)
        case .entityDetail(let seed):
          let entity = Entity(id: seed.id, name: seed.name, type: seed.type)
          EntityDetailView(entityId: seed.id, entityName: seed.name, seed: entity)
        case .userProfile(let seed):
          let user = User(id: seed.id, email: "", username: seed.username).withPicture(seed.pictureUrl)
          ProfileView(
            userId: seed.id,
            seed: user,
            onNavigateToProfile: { userId in
              navigationPath.append(SearchDestination.userProfile(seed: UserSeed(id: userId, username: "", pictureUrl: nil)))
            },
            onNavigateToTasting: nil,
            onNavigateToBottle: { bottleId in
              navigationPath.append(SearchDestination.bottleDetail(seed: BottleSeed(
                id: bottleId, name: "", fullName: "", brandId: "", brandName: "", category: nil, imageUrl: nil, isFavorite: true, hasTasted: false
              )))
            }
          )
        }
      }
    }
    .screenBackground()
  }

  private var searchBar: some View {
    HStack(spacing: 12) {
      SearchInput(placeholder: "Search bottles, brands, users", text: $model.searchText, onSubmit: {
        model.submit()
      })
      .onChange(of: model.searchText) { newValue in
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
    .onChange(of: focused) { isFocused in
      withAnimation { model.isSearching = isFocused }
    }
  }

  @ViewBuilder
  private var content: some View {
    if model.searchText.isEmpty { defaultView } else { resultsView }
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
    case .results(let results):
      if results.isEmpty { noResultsView } else { resultsList(results) }
    case .error(let message):
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
          Button(action: { handleTap(result) }) {
            resultRow(result)
          }
          .buttonStyle(.plain)
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
              .frame(width: DesignSystem.ImageSize.bottleThumb.width, height: DesignSystem.ImageSize.bottleThumb.height)
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
        // Compact status icons: tasted + favorite
        if let bottle = result.bottle {
          HStack(spacing: 6) {
            if bottle.hasTasted {
              Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 12))
                .foregroundColor(.textSecondary)
            }
            if bottle.isFavorite {
              Image(systemName: "star.fill")
                .font(.system(size: 11))
                .foregroundColor(.textSecondary)
            }
          }
        }
        Image(systemName: "chevron.right").font(.caption).foregroundColor(.textSecondary)
      } else if result.type == .user {
        VStack(alignment: .leading, spacing: 4) {
          Text(result.name).font(.body).foregroundColor(.text)
          if let subtitle = result.subtitle, !subtitle.isEmpty {
            Text(subtitle).font(.subheadline).foregroundColor(.textSecondary)
          }
        }
        Spacer()
        
        // Follow/Following button for users
        if let isFollowing = result.isFollowing {
          if isFollowing {
            Text("Following")
              .font(.caption)
              .foregroundColor(.textSecondary)
              .padding(.horizontal, 8)
              .padding(.vertical, 4)
              .background(Color.surfaceSubtle)
              .cornerRadius(8)
          } else {
            Button("Follow") {
              // TODO: Implement follow action
            }
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.brand)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color.brand.opacity(0.1))
            .cornerRadius(12)
          }
        } else {
          Image(systemName: "chevron.right").font(.caption).foregroundColor(.textSecondary)
        }
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

  private var loadingView: some View {
    VStack(spacing: 16) {
      ForEach(0..<5, id: \.self) { _ in
        HStack(spacing: 12) {
          RoundedRectangle(cornerRadius: 8).fill(Color.border.opacity(0.3)).frame(width: 44, height: 44)
          VStack(alignment: .leading, spacing: 4) {
            RoundedRectangle(cornerRadius: 4).fill(Color.border.opacity(0.3)).frame(width: 150, height: 16)
            RoundedRectangle(cornerRadius: 4).fill(Color.border.opacity(0.3)).frame(width: 100, height: 12)
          }
          Spacer()
        }
        .padding(.horizontal)
        .shimmer()
      }
    }
    .padding(.vertical)
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
        .frame(width: DesignSystem.ImageSize.bottleThumb.width, height: DesignSystem.ImageSize.bottleThumb.height)
      
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
            HStack(spacing: 2) {
              Image(systemName: "star.fill")
                .font(.system(size: DesignSystem.FontSize.tiny))
                .foregroundColor(.yellow)
              Text(String(format: "%.1f", bottle.avgRating))
                .font(.system(size: DesignSystem.FontSize.small))
                .foregroundColor(.textSecondary)
            }
          }
        }
      }
      
      Spacer()
      
      // Compact status icons: tasted + favorite
      HStack(spacing: 6) {
        if bottle.hasTasted {
          Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 12))
            .foregroundColor(.textSecondary)
        }
        if bottle.isFavorite {
          Image(systemName: "star.fill")
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
          hasTasted: false
        )
        navigationPath.append(SearchDestination.bottleDetail(seed: s))
      }
    case .entity:
      let e = EntitySeed(id: result.id, name: result.name, type: .brand)
      navigationPath.append(SearchDestination.entityDetail(seed: e))
    case .user:
      let u = UserSeed(id: result.id, username: result.name, pictureUrl: nil)
      navigationPath.append(SearchDestination.userProfile(seed: u))
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
      hasTasted: bottle.hasTasted
    )
    navigationPath.append(SearchDestination.bottleDetail(seed: s))
  }
}
