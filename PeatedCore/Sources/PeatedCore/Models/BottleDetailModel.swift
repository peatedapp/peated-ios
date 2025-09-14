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
  
  public init(bottleId: String, seed: Bottle? = nil) {
    self.bottleId = bottleId
    self.seed = seed
  }
  
  public func loadBottle() async {
    // 1) Show seed immediately if provided
    if let seed {
      self.bottle = seed
      self.state = .loaded(seed)
    }
    // 2) Snapshot-first from normalized store
    if let (cached, _) = await NormalizedStore.shared.get(.bottle(bottleId), as: Bottle.self) {
      self.bottle = cached
      self.state = .loaded(cached)
    } else if self.bottle == nil {
      state = .loading
    }

    do {
      let bottle = try await bottleRepository.getBottle(id: bottleId)
      self.bottle = bottle
      self.state = .loaded(bottle)

      async let recentTastingsTask = loadRecentTastings()
      async let similarBottlesTask = loadSimilarBottles(category: bottle.category)
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
    guard var current = self.bottle else { return }
    let target = !current.isFavorite
    // Optimistic update
    current.isFavorite = target
    self.bottle = current
    if case .loaded = self.state { self.state = .loaded(current) }
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
      self.bottle = current
      if case .loaded = self.state { self.state = .loaded(current) }
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
      self.recentTastings = Array(feedPage.tastings.prefix(5))
    } catch {
      // Silently fail for additional data
      print("Failed to load recent tastings: \(error)")
    }
  }
  
  private func loadSimilarBottles(category: String?) async {
    guard let category = category else { return }
    
    do {
      // For now, just search for bottles in the same category
      // In the future, this could be a dedicated API endpoint
      let bottles = try await bottleRepository.searchBottles(
        query: category,
        limit: 10
      )
      // Filter out the current bottle
      self.similarBottles = bottles.filter { $0.id != bottleId }
    } catch {
      // Silently fail for additional data
      print("Failed to load similar bottles: \(error)")
    }
  }
  
  public func createTasting() {
    // This will be handled by the view presenting the create tasting flow
  }
}
