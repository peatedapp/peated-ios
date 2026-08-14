import Foundation
import Observation
import PeatedCore

@Observable
@MainActor
final class SearchModel {
    var searchText = ""
    var isSearching = false
    var recentSearches: [String] = []
    var state: State = .idle
    var popularBottles: [Bottle] = []
    var topRatedBottles: [Bottle] = []
    var updatingFriendIds: Set<String> = []
    var friendshipErrorMessage: String?

    enum State: Equatable {
        case idle
        case loading
        case results([SearchResult])
        case error(String)
    }

    private let repository: SearchRepository
    private let bottleRepository: BottleRepository
    private let userRepository: any UserRepositoryProtocol
    private var task: Task<Void, Never>?

    init(
        repository: SearchRepository = SearchRepository(),
        bottleRepository: BottleRepository = BottleRepository(),
        userRepository: any UserRepositoryProtocol = UserRepository(),
        loadsPopularContent: Bool = true
    ) {
        self.repository = repository
        self.bottleRepository = bottleRepository
        self.userRepository = userRepository
        loadRecent()
        if loadsPopularContent {
            loadPopularContent()
        }
    }

    func onChange(query: String) {
        task?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            state = .idle
            return
        }
        state = .loading
        task = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: 300_000_000)
                guard !Task.isCancelled else { return }
                let results = try await self?.repository.search(query: trimmed, limit: 50) ?? []
                guard !Task.isCancelled else { return }
                self?.state = .results(results)
            } catch {
                guard !Task.isCancelled else { return }
                self?.state = .error(error.localizedDescription)
            }
        }
    }

    func submit() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        addRecent(query)
    }

    func clear() {
        task?.cancel()
        state = .idle
    }

    func addRecent(_ query: String) {
        var searches = recentSearches
        searches.removeAll { $0.caseInsensitiveCompare(query) == .orderedSame }
        searches.insert(query, at: 0)
        if searches.count > 10 {
            searches = Array(searches.prefix(10))
        }
        recentSearches = searches
        persistRecent()
    }

    func removeRecent(_ query: String) {
        recentSearches.removeAll { $0 == query }
        persistRecent()
    }

    func clearAllRecent() {
        recentSearches = []
        persistRecent()
    }

    func toggleFriendship(for result: SearchResult) async {
        guard result.type == .user,
              !updatingFriendIds.contains(result.id),
              case let .results(results) = state,
              let currentResult = results.first(where: { $0.type == .user && $0.id == result.id }) else {
            return
        }

        let previousStatus = currentResult.friendStatus ?? .none
        let nextStatus: User.FriendStatus = previousStatus == .none ? .pending : .none

        updatingFriendIds.insert(result.id)
        friendshipErrorMessage = nil
        updateFriendStatus(userId: result.id, status: nextStatus)
        defer { updatingFriendIds.remove(result.id) }

        do {
            if previousStatus == .none {
                try await userRepository.followUser(id: result.id)
            } else {
                try await userRepository.unfollowUser(id: result.id)
            }
        } catch {
            updateFriendStatus(userId: result.id, status: previousStatus)
            friendshipErrorMessage = "Couldn't update friendship. Please try again."
        }
    }

    private func loadRecent() {
        recentSearches = UserDefaults.standard.stringArray(forKey: "recentSearches") ?? []
    }

    private func persistRecent() {
        UserDefaults.standard.set(recentSearches, forKey: "recentSearches")
    }

    private func updateFriendStatus(userId: String, status: User.FriendStatus) {
        guard case let .results(results) = state,
              let index = results.firstIndex(where: { $0.type == .user && $0.id == userId }) else {
            return
        }

        var updatedResults = results
        updatedResults[index] = updatedResults[index].withFriendStatus(status)
        state = .results(updatedResults)
    }

    private func loadPopularContent() {
        Task {
            do {
                async let popular = bottleRepository.getPopularBottles(limit: 5)
                async let topRated = bottleRepository.getTopRatedBottles(limit: 5)

                popularBottles = try await popular
                topRatedBottles = try await topRated
            } catch {
                print("Failed to load popular content: \(error)")
            }
        }
    }
}
