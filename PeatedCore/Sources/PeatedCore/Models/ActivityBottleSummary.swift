import Foundation

/// The bottle an activity row is about: enough to render its identity lines and
/// to open the bottle.
public struct ActivityBottleSummary: Hashable, Sendable {
    public let id: String
    public let imageUrl: String?
    public let identity: BottleIdentity

    public init(id: String, imageUrl: String?, identity: BottleIdentity) {
        self.id = id
        self.imageUrl = imageUrl
        self.identity = identity
    }

    public init(_ bottle: Bottle) {
        self.init(id: bottle.id, imageUrl: bottle.imageUrl, identity: BottleIdentity(bottle: bottle))
    }

    public var name: String {
        identity.name
    }
}
