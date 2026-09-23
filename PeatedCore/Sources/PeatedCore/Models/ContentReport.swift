import Foundation

/// Why a member is reporting content. Matches the server's fixed list.
public enum ReportReason: String, CaseIterable, Hashable, Sendable {
    case spam
    case harassment
    case hate
    case sexualContent = "sexual_content"
    case violence
    case inaccurate
    case other

    /// The wording the web app shows for the same reason.
    public var label: String {
        switch self {
        case .spam: "Spam or advertising"
        case .harassment: "Harassment or bullying"
        case .hate: "Hateful content"
        case .sexualContent: "Sexual content"
        case .violence: "Violence or threats"
        case .inaccurate: "Wrong or made-up information"
        case .other: "Something else"
        }
    }

    /// "Something else" means nothing to moderators without the details.
    public var requiresDetails: Bool {
        self == .other
    }
}

/// What a report points at. IDs are the app's string IDs for the object.
public enum ReportTarget: Hashable, Sendable, Identifiable {
    case tasting(id: String)
    case memberReview(id: String)
    case comment(id: String)
    case user(id: String, username: String)
    case bottle(id: String)
    case entity(id: String, type: Entity.EntityType)

    public var id: String {
        switch self {
        case let .tasting(id): "tasting:\(id)"
        case let .memberReview(id): "member-review:\(id)"
        case let .comment(id): "comment:\(id)"
        case let .user(id, _): "user:\(id)"
        case let .bottle(id): "bottle:\(id)"
        case let .entity(id, _): "entity:\(id)"
        }
    }

    /// The phrase the report sheet uses, such as "this tasting" or "@name".
    public var subject: String {
        switch self {
        case .tasting: "this tasting"
        case .memberReview: "this review"
        case .comment: "this comment"
        case let .user(_, username): "@\(username)"
        case .bottle: "this bottle"
        case let .entity(_, type): "this \(type.displayName.lowercased())"
        }
    }
}
