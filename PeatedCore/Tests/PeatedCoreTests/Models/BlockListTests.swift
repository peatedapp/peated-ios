import Foundation
@testable import PeatedCore
import Testing

@MainActor
struct BlockListTests {
    @Test
    func blockingPersistsAndUnblockingRemoves() {
        let store = InMemoryBlockListStore()
        let blockList = BlockList(store: store)

        blockList.add("7")

        #expect(blockList.contains("7"))
        #expect(store.savedIds == ["7"])

        blockList.remove("7")

        #expect(!blockList.contains("7"))
        #expect(store.savedIds.isEmpty)
    }

    @Test
    func loadsPersistedIdsOnStart() {
        let blockList = BlockList(store: InMemoryBlockListStore(ids: ["3", "4"]))

        #expect(blockList.blockedUserIds == ["3", "4"])
    }

    @Test
    func refreshReplacesLocalListWithEveryServerPage() async {
        let store = InMemoryBlockListStore(ids: ["stale"])
        let blockList = BlockList(store: store)
        let repository = BlockingUserRepositoryStub(pages: [
            BlockedUsersPage(users: [blocked("10")], nextCursor: 2),
            BlockedUsersPage(users: [blocked("11")], nextCursor: nil)
        ])

        await blockList.refresh(using: repository)

        let requestedCursors = await repository.requestedCursors
        #expect(blockList.blockedUserIds == ["10", "11"])
        #expect(store.savedIds == ["10", "11"])
        #expect(requestedCursors == [1, 2])
    }

    @Test
    func failedRefreshKeepsLocalList() async {
        let blockList = BlockList(store: InMemoryBlockListStore(ids: ["5"]))

        await blockList.refresh(using: BlockingUserRepositoryStub(failsListing: true))

        #expect(blockList.blockedUserIds == ["5"])
    }

    @Test
    func clearForgetsEveryone() {
        let store = InMemoryBlockListStore(ids: ["5"])
        let blockList = BlockList(store: store)

        blockList.clear()

        #expect(blockList.blockedUserIds.isEmpty)
        #expect(store.savedIds.isEmpty)
    }

    private func blocked(_ id: String) -> BlockedUser {
        BlockedUser(user: User(id: id, email: "", username: "member\(id)"), blockedAt: Date())
    }
}
