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
    public let bottles: PagedList<Bottle>
    public let tastings: PagedList<TastingFeedItem>

    private let entityId: String
    private let seed: Entity?
    private let entityRepository = EntityRepository()
    private let tastingRepository: any TastingRepositoryProtocol

    public init(
        entityId: String,
        seed: Entity? = nil,
        tastings: [TastingFeedItem] = [],
        tastingRepository: (any TastingRepositoryProtocol)? = nil
    ) {
        self.entityId = entityId
        self.seed = seed
        self.tastingRepository = tastingRepository ?? TastingRepository()
        let bottleRepository = BottleRepository()
        let feedRepository = FeedRepository()
        bottles = PagedList(feature: "entity") { cursor in
            try await bottleRepository.getEntityBottles(entityId: entityId, cursor: cursor)
        }
        self.tastings = PagedList(feature: "entity", items: tastings) { cursor in
            try await feedRepository.getEntityTastings(entityId: entityId, cursor: cursor)
        }
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
            async let bottlesLoad: Void = bottles.reload()
            async let tastingsLoad: Void = tastings.reload()
            _ = await (bottlesLoad, tastingsLoad)
        } catch {
            Telemetry.capture(error, feature: "entity", operation: "load")
            if case .loading = state {
                state = .error(error)
            }
        }
    }

    public func retry() async {
        await loadEntity()
    }

    public func toggleToast(for tastingId: String) async {
        guard let original = tastings.items.first(where: { $0.id == tastingId }) else { return }

        tastings.update(id: tastingId) { $0.updatingToast(to: !original.hasToasted) }

        do {
            let hasToasted = try await tastingRepository.toggleToast(tastingId: tastingId)
            tastings.update(id: tastingId) { _ in original.updatingToast(to: hasToasted) }
            if hasToasted {
                ToastManager.shared.showSuccess("Cheers! 🥃")
            }
        } catch {
            Telemetry.capture(error, feature: "entity", operation: "toggle_toast")
            tastings.update(id: tastingId) { _ in original }
            ToastManager.shared.showError("Failed to update toast")
        }
    }
}
