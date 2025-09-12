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
  private let bottleRepository = BottleRepository()
  private let feedRepository = FeedRepository()
  
  public init(bottleId: String) {
    self.bottleId = bottleId
  }
  
  public func loadBottle() async {
    state = .loading
    
    do {
      // Load bottle details
      let bottle = try await bottleRepository.getBottle(id: bottleId)
      self.bottle = bottle
      state = .loaded(bottle)
      
      // Load additional data in parallel
      async let recentTastingsTask = loadRecentTastings()
      async let similarBottlesTask = loadSimilarBottles(category: bottle.category)
      
      _ = await (recentTastingsTask, similarBottlesTask)
    } catch {
      state = .error(error.localizedDescription)
    }
  }
  
  public func refresh() async {
    await loadBottle()
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