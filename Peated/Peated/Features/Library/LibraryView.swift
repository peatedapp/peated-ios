import SwiftUI
import PeatedCore

enum LibraryTab: Int, CaseIterable {
  case collection = 0
  case favorites = 1

  var title: String {
    switch self {
    case .collection: return "Collection"
    case .favorites: return "Favorites"
    }
  }
}

final class LibraryViewModel: ObservableObject {
  @Published var isLoading = false
  @Published var error: String?
  @Published var favorites: [Bottle] = []

  private let repo: CollectionRepository

  init(repo: CollectionRepository = CollectionRepository()) {
    self.repo = repo
  }

  @MainActor
  func loadFavorites() async {
    isLoading = true
    error = nil
    do {
      if let favId = try await repo.getFavoritesCollectionId() {
        let items = try await repo.listBottles(in: favId)
        self.favorites = items
      } else {
        self.favorites = []
      }
    } catch {
      self.error = error.localizedDescription
    }
    isLoading = false
  }
}

struct LibraryView: View {
  @StateObject private var viewModel = LibraryViewModel()
  @State private var selectedTab: LibraryTab = .favorites
  @State private var navigationPath = NavigationPath()

  var body: some View {
    NavigationStack(path: $navigationPath) {
      VStack(spacing: 0) {
        // Tabs
        Picker("LibraryTab", selection: $selectedTab) {
          Text(LibraryTab.collection.title).tag(LibraryTab.collection)
          Text(LibraryTab.favorites.title).tag(LibraryTab.favorites)
        }
        .pickerStyle(.segmented)
        .padding()

        // Content
        Group {
          switch selectedTab {
          case .collection:
            collectionPlaceholder
          case .favorites:
            favoritesList
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.background)
      }
      .background(Color.background)
      .navigationTitle("My Library")
      .navigationBarTitleDisplayMode(.inline)
      .task { await viewModel.loadFavorites() }
      .onChange(of: selectedTab) { newValue in
        if newValue == .favorites {
          Task { await viewModel.loadFavorites() }
        }
      }
      .refreshable { await viewModel.loadFavorites() }
      .navigationDestination(for: String.self) { bottleId in
        BottleDetailView(bottleId: bottleId)
      }
    }
  }

  // MARK: - Views
  private var collectionPlaceholder: some View {
    VStack(spacing: 16) {
      Image(systemName: "shippingbox")
        .font(.system(size: 36))
        .foregroundColor(.textSecondary)
      Text("Collection coming soon")
        .foregroundColor(.textSecondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var favoritesList: some View {
    Group {
      if viewModel.isLoading {
        ProgressView().tint(.brand)
      } else if let err = viewModel.error {
        VStack(spacing: 12) {
          Text("Couldn't load favorites")
            .font(.headline)
          Text(err).font(.footnote).foregroundColor(.textSecondary)
          Button("Retry") { Task { await viewModel.loadFavorites() } }
            .buttonStyle(.borderedProminent)
        }
      } else if viewModel.favorites.isEmpty {
        VStack(spacing: 12) {
          Text("No favorites yet")
            .foregroundColor(.textSecondary)
          Text("Tap the star on a bottle to save it here.")
            .font(.footnote)
            .foregroundColor(.textSecondary)
        }
      } else {
        ScrollView {
          LazyVStack(spacing: 12) {
            ForEach(viewModel.favorites, id: \.id) { bottle in
              BottleRow(bottle: bottle) {
                navigationPath.append(bottle.id)
              }
            }
          }
          .padding(.horizontal)
          .padding(.top, 8)
        }
      }
    }
  }
}
