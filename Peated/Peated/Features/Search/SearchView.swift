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
  
  enum SearchDestination: Hashable {
    case bottleDetail(bottleId: String, bottleName: String?)
    case entityDetail(entityId: String, entityName: String?)
    case userProfile(userId: String, username: String?)
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
      .navigationDestination(for: SearchDestination.self) { destination in
        switch destination {
        case .bottleDetail(let bottleId, let bottleName):
          BottleDetailView(bottleId: bottleId, bottleName: bottleName)
        case .entityDetail(let entityId, let entityName):
          EntityDetailView(entityId: entityId, entityName: entityName)
        case .userProfile(let userId, let username):
          ProfileView(userId: userId)
        }
      }
    }
  }

  private var searchBar: some View {
    HStack(spacing: 12) {
      HStack {
        Image(systemName: "magnifyingglass").foregroundColor(.secondary)
        TextField("Search bottles, brands, users", text: $model.searchText)
          .textFieldStyle(.plain)
          .focused($focused)
          .onSubmit { model.submit() }
          .onChange(of: model.searchText) { newValue in
            model.onChange(query: newValue)
          }
        if !model.searchText.isEmpty {
          Button(action: {
            model.searchText = ""
            model.clear()
          }) {
            Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
          }
        }
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 10)
      .background(Color(.secondarySystemBackground))
      .cornerRadius(10)

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
          .foregroundColor(.accentColor)
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
                .foregroundColor(.secondary)
              
              Text(query)
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
              
              Button(action: { model.removeRecent(query) }) {
                Image(systemName: "xmark")
                  .font(.caption)
                  .foregroundColor(.secondary)
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
      .background(Color(.secondarySystemBackground))
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
        .foregroundColor(.secondary)
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
      .background(Color(.secondarySystemBackground))
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
            Image(systemName: "wineglass").font(.title2).foregroundColor(.secondary)
              .frame(width: 44, height: 44)
              .background(Color(.tertiarySystemBackground))
              .cornerRadius(8)
          }
        case .entity:
          Image(systemName: "building.2").font(.title2).foregroundColor(.secondary)
            .frame(width: 44, height: 44)
            .background(Color(.tertiarySystemBackground))
            .cornerRadius(8)
        case .user:
          Image(systemName: "person.crop.circle").font(.title2).foregroundColor(.secondary)
            .frame(width: 44, height: 44)
        }
      }

      if result.type == .bottle, let bottle = result.bottle {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxSmall) {
          Text(bottle.fullName)
            .font(.system(size: DesignSystem.FontSize.title, weight: .semibold))
            .foregroundColor(.primary)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
          HStack(spacing: DesignSystem.Spacing.xSmall) {
            Text(bottle.brandName)
              .font(.system(size: DesignSystem.FontSize.body))
              .foregroundColor(.secondary)
              .lineLimit(1)
              .truncationMode(.tail)
            if let category = bottle.category {
              Text("•").foregroundColor(.secondary.opacity(0.5))
              Text(category.replacingOccurrences(of: "_", with: " ").capitalized)
                .font(.system(size: DesignSystem.FontSize.body))
                .foregroundColor(.secondary)
            }
          }
        }
        Spacer(minLength: DesignSystem.Spacing.small)
        Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
      } else if result.type == .user {
        VStack(alignment: .leading, spacing: 4) {
          Text(result.name).font(.body).foregroundColor(.primary)
          if let subtitle = result.subtitle, !subtitle.isEmpty {
            Text(subtitle).font(.subheadline).foregroundColor(.secondary)
          }
        }
        Spacer()
        
        // Follow/Following button for users
        if let isFollowing = result.isFollowing {
          if isFollowing {
            Text("Following")
              .font(.caption)
              .foregroundColor(.secondary)
              .padding(.horizontal, 8)
              .padding(.vertical, 4)
              .background(Color(.tertiarySystemBackground))
              .cornerRadius(8)
          } else {
            Button("Follow") {
              // TODO: Implement follow action
            }
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(.accentColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(12)
          }
        } else {
          Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
        }
      } else {
        VStack(alignment: .leading, spacing: 4) {
          Text(result.name).font(.body).foregroundColor(.primary)
          if let subtitle = result.subtitle, !subtitle.isEmpty {
            Text(subtitle).font(.subheadline).foregroundColor(.secondary)
          }
        }
        Spacer()
        Image(systemName: "chevron.right").font(.caption).foregroundColor(.secondary)
      }
    }
    .padding(.horizontal)
    .padding(.vertical, 12)
  }

  private var loadingView: some View {
    VStack(spacing: 16) {
      ForEach(0..<5, id: \.self) { _ in
        HStack(spacing: 12) {
          RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.3)).frame(width: 44, height: 44)
          VStack(alignment: .leading, spacing: 4) {
            RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.3)).frame(width: 150, height: 16)
            RoundedRectangle(cornerRadius: 4).fill(Color.gray.opacity(0.3)).frame(width: 100, height: 12)
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
      Image(systemName: "magnifyingglass").font(.system(size: 50)).foregroundColor(.secondary)
      Text("No results for \"\(model.searchText)\"").font(.title3).fontWeight(.semibold)
      Text("Try searching for something else").font(.body).foregroundColor(.secondary)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private func errorView(_ message: String) -> some View {
    VStack(spacing: 8) {
      Image(systemName: "exclamationmark.triangle").foregroundColor(.orange)
      Text("Search failed").font(.headline)
      Text(message).font(.footnote).foregroundColor(.secondary)
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
      .background(Color(.secondarySystemBackground))
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
      .background(Color(.secondarySystemBackground))
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
          .foregroundColor(.primary)
          .lineLimit(2)
          .fixedSize(horizontal: false, vertical: true)
        
        HStack(spacing: DesignSystem.Spacing.xSmall) {
          if let category = bottle.category {
            Text(category.replacingOccurrences(of: "_", with: " ").capitalized)
              .font(.system(size: DesignSystem.FontSize.small))
              .foregroundColor(.secondary)
          }
          
          if bottle.totalRatings > 0 {
            Text("•").foregroundColor(.secondary.opacity(0.5))
            HStack(spacing: 2) {
              Image(systemName: "star.fill")
                .font(.system(size: DesignSystem.FontSize.tiny))
                .foregroundColor(.yellow)
              Text(String(format: "%.1f", bottle.avgRating))
                .font(.system(size: DesignSystem.FontSize.small))
                .foregroundColor(.secondary)
            }
          }
        }
      }
      
      Spacer()
      
      Image(systemName: "chevron.right")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .padding(.horizontal)
    .padding(.vertical, 12)
  }
  
  private func handleTap(_ result: SearchResult) {
    model.addRecent(result.name)
    
    switch result.type {
    case .bottle:
      if let bottle = result.bottle {
        navigationPath.append(SearchDestination.bottleDetail(bottleId: bottle.id, bottleName: bottle.fullName))
      } else {
        navigationPath.append(SearchDestination.bottleDetail(bottleId: result.id, bottleName: result.name))
      }
    case .entity:
      navigationPath.append(SearchDestination.entityDetail(entityId: result.id, entityName: result.name))
    case .user:
      navigationPath.append(SearchDestination.userProfile(userId: result.id, username: result.name))
    }
  }
  
  private func handleBottleTap(_ bottle: Bottle) {
    model.addRecent(bottle.fullName)
    navigationPath.append(SearchDestination.bottleDetail(bottleId: bottle.id, bottleName: bottle.fullName))
  }
}
