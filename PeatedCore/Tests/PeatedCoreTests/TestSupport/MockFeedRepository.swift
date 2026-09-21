import Foundation
@testable import PeatedCore

/// Mock implementation of FeedRepositoryProtocol for testing
@MainActor
public class MockFeedRepository: FeedRepositoryProtocol {
    // MARK: - Mock Configuration

    public var mockPage: ActivityPage?
    public var mockError: Error?
    public var networkDelay: TimeInterval = 0

    // MARK: - Call Tracking

    public var getFeedCallCount = 0
    public var refreshFeedCallCount = 0
    public var lastFeedType: FeedType?
    public var lastCursor: String?
    public var lastLimit: Int?

    // MARK: - Call History

    public struct FeedCall {
        let type: FeedType
        let cursor: String?
        let limit: Int
        let timestamp: Date
    }

    public private(set) var getFeedCalls: [FeedCall] = []
    public private(set) var refreshFeedCalls: [FeedCall] = []

    public init() {}

    // MARK: - FeedRepositoryProtocol Implementation

    public func getActivity(type: FeedType, cursor: String?, limit: Int) async throws -> ActivityPage {
        getFeedCallCount += 1
        lastFeedType = type
        lastCursor = cursor
        lastLimit = limit

        // Record call for detailed tracking
        getFeedCalls.append(FeedCall(
            type: type,
            cursor: cursor,
            limit: limit,
            timestamp: Date()
        ))

        return try await response()
    }

    public func refreshActivity(type: FeedType) async throws -> ActivityPage {
        refreshFeedCallCount += 1

        // Record refresh call
        refreshFeedCalls.append(FeedCall(
            type: type,
            cursor: nil,
            limit: 20,
            timestamp: Date()
        ))

        return try await response()
    }

    public func getBottleTastings(
        bottleId _: String,
        cursor: String?,
        limit: Int
    ) async throws -> FeedPage {
        try await tastingPage(type: .global, cursor: cursor, limit: limit)
    }

    public func getUserTastings(
        userId _: String,
        cursor: String?,
        limit: Int
    ) async throws -> FeedPage {
        try await tastingPage(type: .friends, cursor: cursor, limit: limit)
    }

    // MARK: - Test Helpers

    public func reset() {
        getFeedCallCount = 0
        refreshFeedCallCount = 0
        getFeedCalls.removeAll()
        refreshFeedCalls.removeAll()
        lastFeedType = nil
        lastCursor = nil
        lastLimit = nil
        mockError = nil
        mockPage = nil
        networkDelay = 0
    }

    public func wasGetFeedCalled(for type: FeedType) -> Bool {
        getFeedCalls.contains { $0.type == type }
    }

    public func wasRefreshFeedCalled(for type: FeedType) -> Bool {
        refreshFeedCalls.contains { $0.type == type }
    }

    public var totalCallCount: Int {
        getFeedCallCount + refreshFeedCallCount
    }

    private func tastingPage(type: FeedType, cursor: String?, limit: Int) async throws -> FeedPage {
        let page = try await getActivity(type: type, cursor: cursor, limit: limit)
        return FeedPage(tastings: page.entries.compactMap(\.tasting), cursor: page.cursor, hasMore: page.hasMore)
    }

    private func response() async throws -> ActivityPage {
        if networkDelay > 0 {
            try await Task.sleep(for: .seconds(networkDelay))
        }

        if let error = mockError {
            throw error
        }

        return mockPage ?? ActivityPage(entries: [], cursor: nil, hasMore: false)
    }
}
