@testable import PeatedCore
import Testing

struct FeedRepositoryTests {
    @Test
    func friendsFeedUsesFriendsFilter() throws {
        let query = try FeedRepository.makeFeedQuery(
            type: .friends,
            cursor: "42",
            limit: 25,
            currentUserId: "7"
        )

        #expect(query.filter == .friends)
        #expect(query.user == nil)
        #expect(query.cursor == 42)
        #expect(query.limit == 25)
    }

    @Test
    func globalFeedUsesGlobalFilter() throws {
        let query = try FeedRepository.makeFeedQuery(
            type: .global,
            cursor: nil,
            limit: 20,
            currentUserId: "7"
        )

        #expect(query.filter == .global)
        #expect(query.user == nil)
    }

    @Test
    func personalFeedUsesCurrentUser() throws {
        let query = try FeedRepository.makeFeedQuery(
            type: .personal,
            cursor: nil,
            limit: 20,
            currentUserId: "7"
        )

        #expect(query.filter == nil)
        #expect(query.user?.value1 == 7)
    }
}
