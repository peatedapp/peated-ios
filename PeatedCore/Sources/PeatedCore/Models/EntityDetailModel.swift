import Foundation
import Observation

@Observable
@MainActor
public final class EntityDetailModel {
    public enum State {
        case loading
        case loaded(Entity)
        case error(Error)
    }

    public private(set) var state: State = .loading
    public private(set) var bottles: [Bottle] = []
    public private(set) var recentTastings: [TastingFeedItem] = []
    public private(set) var isLoadingBottles = false
    public private(set) var isLoadingTastings = false

    private let entityId: String
    private let seed: Entity?
    private let entityRepository = EntityRepository()
    private let bottleRepository = BottleRepository()
    private let feedRepository = FeedRepository()
    private let tastingRepository: any TastingRepositoryProtocol

    public init(
        entityId: String,
        seed: Entity? = nil,
        recentTastings: [TastingFeedItem] = [],
        tastingRepository: (any TastingRepositoryProtocol)? = nil
    ) {
        self.entityId = entityId
        self.seed = seed
        self.recentTastings = recentTastings
        self.tastingRepository = tastingRepository ?? TastingRepository()
    }

    public func loadEntity() async {
        // 1) Seed immediately if provided
        if let seed {
            state = .loaded(seed)
        }
        // 2) Snapshot-first
        if let (cached, _) = await NormalizedStore.shared.get(.entity(entityId), as: Entity.self) {
            state = .loaded(cached)
        } else if case .loaded = state {
            // keep seeded
        } else {
            state = .loading
        }

        do {
            let entity = try await entityRepository.getEntity(id: entityId)
            state = .loaded(entity)

            // Load related data in parallel
            await withTaskGroup(of: Void.self) { group in
                group.addTask { [weak self] in
                    await self?.loadBottles(entityId: entity.id)
                }

                group.addTask { [weak self] in
                    await self?.loadRecentTastings(entityId: entity.id)
                }
            }
        } catch {
            if case .loading = state {
                state = .error(error)
            }
        }
    }

    private func loadBottles(entityId: String) async {
        isLoadingBottles = true
        defer { isLoadingBottles = false }

        do {
            // Fetch bottles for this entity (brand/distillery)
            bottles = try await bottleRepository.getEntityBottles(entityId: entityId)
        } catch {
            // Log error but don't fail the whole view
            print("Failed to load bottles for entity: \(error)")
            bottles = []
        }
    }

    private func loadRecentTastings(entityId: String) async {
        isLoadingTastings = true
        defer { isLoadingTastings = false }

        do {
            // Fetch recent tastings for bottles from this entity
            let feedPage = try await feedRepository.getEntityTastings(entityId: entityId)
            recentTastings = feedPage.tastings
        } catch {
            // Log error but don't fail the whole view
            print("Failed to load tastings for entity: \(error)")
            recentTastings = []
        }
    }

    public func retry() async {
        await loadEntity()
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
