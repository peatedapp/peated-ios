@testable import PeatedCore

actor CollectionRepositoryStub: CollectionRepositoryProtocol {
    enum StubError: Error {
        case mutationFailed
    }

    private(set) var addedBottleIds: [String] = []
    private(set) var removedBottleIds: [String] = []
    let shouldFailMutation: Bool

    init(shouldFailMutation: Bool = false) {
        self.shouldFailMutation = shouldFailMutation
    }

    func listLibraryEntries(
        user _: String,
        query _: String?,
        status _: LibraryBottleStatus?,
        cursor _: Int,
        limit _: Int
    ) async throws -> ListPage<LibraryEntry> {
        ListPage(items: [], nextCursor: nil)
    }

    func addBottleToLibrary(bottleId: String, user _: String) async throws {
        if shouldFailMutation {
            throw StubError.mutationFailed
        }
        addedBottleIds.append(bottleId)
    }

    func removeBottleFromLibrary(bottleId: String, user _: String) async throws {
        if shouldFailMutation {
            throw StubError.mutationFailed
        }
        removedBottleIds.append(bottleId)
    }
}
