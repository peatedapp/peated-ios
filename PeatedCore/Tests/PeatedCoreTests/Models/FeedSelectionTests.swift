import Foundation
@testable import PeatedCore
import Testing

@MainActor
struct FeedSelectionTests {
    @Test("The feed opens on Global when nothing is remembered")
    func defaultsToGlobal() {
        let model = FeedModel(feedRepository: MockFeedRepository(), selectionStore: InMemoryFeedSelectionStore())

        #expect(model.selectedFeedType == .global)
    }

    @Test("The feed reopens on the remembered selection")
    func reopensOnRememberedSelection() {
        let store = InMemoryFeedSelectionStore(selection: .friends)
        let model = FeedModel(feedRepository: MockFeedRepository(), selectionStore: store)

        #expect(model.selectedFeedType == .friends)
    }

    @Test("Switching feeds remembers the new selection")
    func switchingRemembersSelection() async {
        let store = InMemoryFeedSelectionStore()
        let model = FeedModel(feedRepository: MockFeedRepository(), selectionStore: store)

        await model.switchFeedType(.friends)

        #expect(store.selection == .friends)
    }

    @Test("User defaults store round-trips the selection")
    func userDefaultsStoreRoundTrips() throws {
        let suiteName = "FeedSelectionTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = UserDefaultsFeedSelectionStore(defaults: defaults)

        #expect(store.loadSelection() == nil)
        store.saveSelection(.friends)
        #expect(store.loadSelection() == .friends)
    }
}
