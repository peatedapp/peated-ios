import Foundation
@testable import PeatedAPI
@testable import PeatedCore
import Testing

struct UserTests {
    @Test
    func mapsDeletionScheduledAtForTheSignedInMember() {
        let scheduledAt = Date(timeIntervalSince1970: 1_800_000_000)
        let apiUser = Components.Schemas.User(
            id: 1,
            username: "jane",
            email: "jane@example.com",
            deletionScheduledAt: scheduledAt
        )

        let user = User(from: apiUser)

        #expect(user.id == "1")
        #expect(user.deletionScheduledAt == scheduledAt)
    }

    @Test
    func leavesDeletionScheduledAtEmptyWhenTheAPIOmitsIt() {
        let user = User(from: Components.Schemas.User(id: 2, username: "sam"))

        #expect(user.deletionScheduledAt == nil)
    }

    @Test
    func withDeletionScheduleKeepsLocallyLoadedStats() {
        var current = User(id: "1", email: "jane@example.com", username: "jane")
        current.tastingsCount = 12
        current.bottlesCount = 4
        current.friendStatus = .friends
        var fresh = User(id: "1", email: "jane@example.com", username: "jane")
        fresh.deletionScheduledAt = Date(timeIntervalSince1970: 1_800_000_000)

        let scheduled = current.withDeletionSchedule(from: fresh)
        let kept = scheduled.withDeletionSchedule(from: current)

        #expect(scheduled.deletionScheduledAt == fresh.deletionScheduledAt)
        #expect(scheduled.tastingsCount == 12)
        #expect(scheduled.bottlesCount == 4)
        #expect(scheduled.friendStatus == .friends)
        #expect(kept.deletionScheduledAt == nil)
        #expect(kept.tastingsCount == 12)
    }
}
