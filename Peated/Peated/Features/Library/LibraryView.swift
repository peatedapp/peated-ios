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

  struct BottleNav: Hashable {
    let id: String
    let name: String
    let fullName: String
    let brandId: String
    let brandName: String
    let category: String?
    let imageUrl: String?
    let isFavorite: Bool
    let hasTasted: Bool
  }

  var body: some View {
    NavigationStack(path: $navigationPath) {
      VStack(spacing: 0) {
        // Tabs (custom, dark friendly)
        HStack(spacing: 0) {
          ForEach(LibraryTab.allCases, id: \.self) { tab in
            Button(action: { selectedTab = tab }) {
              VStack(spacing: 0) {
                Text(tab.title)
                  .font(.system(size: 15, weight: selectedTab == tab ? .medium : .regular))
                  .foregroundColor(selectedTab == tab ? Color.text : Color.textSecondary)
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 12)
                Rectangle()
                  .fill(selectedTab == tab ? Color.brand : Color.clear)
                  .frame(height: 2)
              }
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .overlay(
          Rectangle().fill(Color.border.opacity(0.2)).frame(height: 1),
          alignment: .bottom
        )

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
      }
      
      .navigationTitle("My Library")
      .navigationBarTitleDisplayMode(.inline)
      .navigationChrome()
      .task { await viewModel.loadFavorites() }
      .onChange(of: selectedTab) { newValue in
        if newValue == .favorites {
          Task { await viewModel.loadFavorites() }
        }
      }
      .refreshable { await viewModel.loadFavorites() }
      .navigationDestination(for: BottleNav.self) { nav in
        let bottle = Bottle(
          id: nav.id,
          name: nav.name,
          fullName: nav.fullName,
          brand: Brand(id: nav.brandId, name: nav.brandName),
          category: nav.category,
          imageUrl: nav.imageUrl,
          isFavorite: nav.isFavorite,
          hasTasted: nav.hasTasted
        )
        BottleDetailView(bottleId: nav.id, bottleName: nav.fullName, seed: bottle)
      }
    }
    .screenBackground()
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
                let nav = BottleNav(
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
                navigationPath.append(nav)
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
