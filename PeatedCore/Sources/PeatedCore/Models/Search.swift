import Foundation

public enum SearchResultType: String, Codable, Sendable, CaseIterable {
    case bottle
    case entity
    case user
}

public struct SearchResult: Identifiable, Equatable, Sendable {
    public let id: String
    public let type: SearchResultType
    public let name: String
    public let subtitle: String?
    public let imageUrl: String?
    public let rating: Double?
    public let ratingCount: Int?
    public let friendStatus: User.FriendStatus?
    public let bottle: Bottle?

    public init(
        id: String,
        type: SearchResultType,
        name: String,
        subtitle: String? = nil,
        imageUrl: String? = nil,
        rating: Double? = nil,
        ratingCount: Int? = nil,
        friendStatus: User.FriendStatus? = nil,
        bottle: Bottle? = nil
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.subtitle = subtitle
        self.imageUrl = imageUrl
        self.rating = rating
        self.ratingCount = ratingCount
        self.friendStatus = friendStatus
        self.bottle = bottle
    }

    public func withFriendStatus(_ friendStatus: User.FriendStatus) -> SearchResult {
        SearchResult(
            id: id,
            type: type,
            name: name,
            subtitle: subtitle,
            imageUrl: imageUrl,
            rating: rating,
            ratingCount: ratingCount,
            friendStatus: friendStatus,
            bottle: bottle
        )
    }
}

public extension SearchResultType {
    var sectionTitle: String {
        switch self {
        case .bottle: "BOTTLES"
        case .entity: "BRANDS & DISTILLERIES"
        case .user: "USERS"
        }
    }
}
