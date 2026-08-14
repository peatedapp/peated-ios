import Foundation

public enum LibraryBottleStatus: String, Codable, CaseIterable, Hashable, Sendable {
    case sealed
    case open
    case empty

    public var displayName: String {
        switch self {
        case .sealed: "Sealed"
        case .open: "Open"
        case .empty: "Empty"
        }
    }
}

public struct LibraryEntry: Equatable, Sendable, Identifiable {
    public let id: String
    public let bottle: Bottle
    public let imageUrl: String?
    public let status: LibraryBottleStatus?

    public init(
        id: String,
        bottle: Bottle,
        imageUrl: String? = nil,
        status: LibraryBottleStatus? = nil
    ) {
        self.id = id
        self.bottle = bottle
        self.imageUrl = imageUrl
        self.status = status
    }
}
