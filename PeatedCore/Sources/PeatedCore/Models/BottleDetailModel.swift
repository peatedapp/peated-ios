import Foundation
import Observation
import PeatedAPI

@Observable
@MainActor
public final class BottleDetailModel {
    public enum ViewState: Equatable {
        case loading
        case loaded(Bottle)
        case error(String)
    }

    public private(set) var state: ViewState = .loading
    public private(set) var bottle: Bottle?
    public private(set) var recentTastings: [TastingFeedItem] = []
    public private(set) var similarBottles: [Bottle] = []

    private let bottleId: String
    private let seed: Bottle?
    private let bottleRepository = BottleRepository()
    private let feedRepository = FeedRepository()
    private let collectionRepository = CollectionRepository()
    private let tastingRepository: any TastingRepositoryProtocol

    public init(
        bottleId: String,
        seed: Bottle? = nil,
        recentTastings: [TastingFeedItem] = [],
        tastingRepository: (any TastingRepositoryProtocol)? = nil
    ) {
        self.bottleId = bottleId
        self.seed = seed
        self.recentTastings = recentTastings
        self.tastingRepository = tastingRepository ?? TastingRepository()
    }

    public func loadBottle() async {
        // 1) Show seed immediately if provided
        if let seed {
            bottle = seed
            state = .loaded(seed)
        }
        // 2) Snapshot-first from normalized store
        if let (cached, _) = await NormalizedStore.shared.get(.bottle(bottleId), as: Bottle.self) {
            bottle = cached
            state = .loaded(cached)
        } else if bottle == nil {
            state = .loading
        }

        do {
            let bottle = try await bottleRepository.getBottle(id: bottleId)
            self.bottle = bottle
            state = .loaded(bottle)

            async let recentTastingsTask: Void = loadRecentTastings()
            async let similarBottlesTask: Void = loadSimilarBottles(category: bottle.category)
            _ = await (recentTastingsTask, similarBottlesTask)
        } catch {
            if case .loading = state {
                state = .error(error.localizedDescription)
            }
        }
    }

    public func refresh() async {
        await loadBottle()
    }

    public func toggleFavorite() async {
        guard var current = bottle else { return }
        let target = !current.isFavorite
        // Optimistic update
        current.isFavorite = target
        bottle = current
        if case .loaded = state {
            state = .loaded(current)
        }
        await NormalizedStore.shared.upsert(.bottle(current.id), value: current)

        do {
            if target {
                try await collectionRepository.addBottleToFavorites(bottleId: bottleId)
            } else {
                try await collectionRepository.removeBottleFromFavorites(bottleId: bottleId)
            }
        } catch {
            // Revert on failure
            current.isFavorite.toggle()
            bottle = current
            if case .loaded = state {
                state = .loaded(current)
            }
            await NormalizedStore.shared.upsert(.bottle(current.id), value: current)
            print("Failed to toggle favorite: \(error)")
        }
    }

    private func loadRecentTastings() async {
        do {
            // Load tastings specifically for this bottle
            let feedPage = try await feedRepository.getBottleTastings(
                bottleId: bottleId,
                cursor: nil,
                limit: 10
            )
            recentTastings = Array(feedPage.tastings.prefix(5))
        } catch {
            // Silently fail for additional data
            print("Failed to load recent tastings: \(error)")
        }
    }

    private func loadSimilarBottles(category: String?) async {
        guard let category else { return }

        do {
            // For now, just search for bottles in the same category
            // In the future, this could be a dedicated API endpoint
            let bottles = try await bottleRepository.searchBottles(
                query: category,
                limit: 10
            )
            // Filter out the current bottle
            similarBottles = bottles.filter { $0.id != bottleId }
        } catch {
            // Silently fail for additional data
            print("Failed to load similar bottles: \(error)")
        }
    }

    public func createTasting() {
        // This will be handled by the view presenting the create tasting flow
    }

    public func toggleToast(for tastingId: String) async {
        guard let index = recentTastings.firstIndex(where: { $0.id == tastingId }) else { return }

        let original = recentTastings[index]
        recentTastings[index] = original.updatingToast(to: !original.hasToasted)

        do {
            let hasToasted = try await tastingRepository.toggleToast(tastingId: tastingId)
            if let currentIndex = recentTastings.firstIndex(where: { $0.id == tastingId }) {
                recentTastings[currentIndex] = original.updatingToast(to: hasToasted)
            }
            if hasToasted {
                ToastManager.shared.showSuccess("Cheers! 🥃")
            }
        } catch {
            if let currentIndex = recentTastings.firstIndex(where: { $0.id == tastingId }) {
                recentTastings[currentIndex] = original
            }
            ToastManager.shared.showError("Failed to update toast")
        }
    }
}
