import PeatedCore
import SwiftUI

private enum LibraryFilter: Hashable, CaseIterable {
    case all
    case status(LibraryBottleStatus)

    static var allCases: [LibraryFilter] {
        [.all] + LibraryBottleStatus.allCases.map(.status)
    }

    var title: String {
        switch self {
        case .all: "All"
        case let .status(status): status.displayName
        }
    }

    var status: LibraryBottleStatus? {
        switch self {
        case .all: nil
        case let .status(status): status
        }
    }
}

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published private(set) var isLoading = false
    @Published private(set) var error: String?
    @Published private(set) var entries: [LibraryEntry] = []

    private let repository: any CollectionRepositoryProtocol
    private var loadGeneration = 0

    init(repository: (any CollectionRepositoryProtocol)? = nil) {
        self.repository = repository ?? CollectionRepository()
    }

    func load(status: LibraryBottleStatus? = nil) async {
        loadGeneration += 1
        let generation = loadGeneration
        isLoading = true
        error = nil
        defer {
            if generation == loadGeneration {
                isLoading = false
            }
        }

        do {
            let entries = try await repository.listLibraryEntries(
                user: "me",
                query: nil,
                status: status,
                limit: 100
            )
            guard generation == loadGeneration else { return }
            self.entries = entries
        } catch {
            guard generation == loadGeneration else { return }
            self.error = error.localizedDescription
        }
    }
}

struct LibraryView: View {
    @StateObject private var viewModel = LibraryViewModel()
    @State private var selectedFilter = LibraryFilter.all
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
        let isLibrary: Bool
        let hasTasted: Bool
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                libraryFilters
                libraryContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("My Library")
            .navigationBarTitleDisplayMode(.inline)
            .navigationChrome()
            .task(id: selectedFilter) {
                await viewModel.load(status: selectedFilter.status)
            }
            .navigationDestination(for: BottleNav.self) { nav in
                let bottle = Bottle(
                    id: nav.id,
                    name: nav.name,
                    fullName: nav.fullName,
                    brand: Brand(id: nav.brandId, name: nav.brandName),
                    category: nav.category,
                    imageUrl: nav.imageUrl,
                    isFavorite: nav.isFavorite,
                    isLibrary: nav.isLibrary,
                    hasTasted: nav.hasTasted
                )
                BottleDetailView(
                    bottleId: nav.id,
                    bottleName: nav.fullName,
                    seed: bottle,
                    navigationPath: $navigationPath
                )
            }
            .tastingActivityNavigationDestinations(path: $navigationPath)
        }
        .screenBackground()
    }

    private var libraryFilters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(LibraryFilter.allCases, id: \.self) { filter in
                    Button(filter.title) {
                        selectedFilter = filter
                    }
                    .font(.system(size: 14, weight: selectedFilter == filter ? .semibold : .regular))
                    .foregroundColor(selectedFilter == filter ? .onBrand : .textSecondary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(selectedFilter == filter ? Color.brand : Color.border.opacity(0.3))
                    .clipShape(Capsule())
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selectedFilter == filter ? .isSelected : [])
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .overlay(
            Rectangle().fill(Color.border.opacity(0.2)).frame(height: 1),
            alignment: .bottom
        )
    }

    @ViewBuilder
    private var libraryContent: some View {
        if viewModel.isLoading {
            LibrarySkeleton()
        } else if let error = viewModel.error {
            VStack(spacing: 12) {
                Text("Couldn't load your library")
                    .font(.headline)
                Text(error)
                    .font(.footnote)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                Button("Retry") {
                    Task { await viewModel.load(status: selectedFilter.status) }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 32)
        } else if viewModel.entries.isEmpty {
            emptyLibrary
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.entries) { entry in
                        BottleRow(
                            bottle: entry.bottle,
                            subtitle: .libraryStatus(entry.status)
                        ) {
                            navigationPath.append(BottleNav(entry: entry))
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .refreshable {
                await viewModel.load(status: selectedFilter.status)
            }
        }
    }

    private var emptyLibrary: some View {
        VStack(spacing: 12) {
            Image(systemName: "books.vertical")
                .font(.system(size: 38))
                .foregroundColor(.textSecondary)
            Text(selectedFilter == .all ? "Build your bottle library" : "No matching bottles")
                .font(.headline)
            Text(emptyLibraryMessage)
                .font(.footnote)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
    }

    private var emptyLibraryMessage: String {
        if selectedFilter == .all {
            "Save bottles from their detail pages, then track whether they are sealed, open, or empty."
        } else {
            "No bottles in your library have this status."
        }
    }
}

private extension LibraryView.BottleNav {
    init(entry: LibraryEntry) {
        let bottle = entry.bottle
        self.init(
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
    }
}
