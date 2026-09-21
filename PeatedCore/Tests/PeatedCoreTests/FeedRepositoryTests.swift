@testable import PeatedCore
import Testing

struct FeedRepositoryTests {
    @Test
    func friendsFeedUsesFriendsFilterWithoutCritics() {
        let query = FeedRepository.makeActivityQuery(type: .friends, cursor: "abc", limit: 25)

        #expect(query.filter == .friends)
        #expect(query.includeCriticReviews == nil)
        #expect(query.cursor == "abc")
        #expect(query.limit == 25)
    }

    @Test
    func globalFeedIncludesCriticReviews() {
        let query = FeedRepository.makeActivityQuery(type: .global, cursor: nil, limit: 20)

        #expect(query.filter == .global)
        #expect(query.includeCriticReviews == true)
        #expect(query.cursor == nil)
        #expect(query.limit == 20)
    }
}
