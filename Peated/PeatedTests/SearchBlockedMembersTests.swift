@testable import Peated
import PeatedCore
import Testing

@MainActor
struct SearchBlockedMembersTests {
    @Test
    func hidesBlockedMembersButKeepsEverythingElse() {
        let blockList = BlockList(store: InMemoryBlockListStore(ids: ["7"]))
        let results = [
            SearchResult(id: "7", type: .user, name: "blocked"),
            SearchResult(id: "8", type: .user, name: "friend"),
            SearchResult(id: "7", type: .bottle, name: "Lagavulin 16")
        ]

        let visible = SearchModel.hidingBlockedMembers(results, blockList: blockList)

        #expect(visible.map(\.name) == ["friend", "Lagavulin 16"])
    }
}
