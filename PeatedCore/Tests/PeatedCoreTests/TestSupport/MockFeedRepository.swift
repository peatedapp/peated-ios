import Foundation
@testable import PeatedCore

/// Mock implementation of FeedRepositoryProtocol for testing
@MainActor
public class MockFeedRepository: FeedRepositoryProtocol {
    // MARK: - Mock Configuration
    public var mockFeedPage: FeedPage?
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
    
    public func getFeed(type: FeedType, cursor: String?, limit: Int) async throws -> FeedPage {
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
        
        // Simulate network delay if configured
        if networkDelay > 0 {
            try await Task.sleep(for: .seconds(networkDelay))
        }
        
        // Throw error if configured
        if let error = mockError {
            throw error
        }
        
        // Return mock data or empty page
        return mockFeedPage ?? FeedPage(tastings: [], cursor: nil, hasMore: false)
    }
    
    public func refreshFeed(type: FeedType) async throws -> FeedPage {
        refreshFeedCallCount += 1
        
        // Record refresh call
        refreshFeedCalls.append(FeedCall(
            type: type,
            cursor: nil,
            limit: 20,
            timestamp: Date()
        ))
        
        // Refresh is just a getFeed with no cursor
        return try await getFeed(type: type, cursor: nil, limit: 20)
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
        mockFeedPage = nil
        networkDelay = 0
    }
    
    public func wasGetFeedCalled(for type: FeedType) -> Bool {
        return getFeedCalls.contains { $0.type == type }
    }
    
    public func wasRefreshFeedCalled(for type: FeedType) -> Bool {
        return refreshFeedCalls.contains { $0.type == type }
    }
    
    public var totalCallCount: Int {
        getFeedCallCount + refreshFeedCallCount
    }
}