import Foundation
import OpenAPIRuntime
import PeatedAPI

public enum RatingValue: Int, CaseIterable, Codable, Hashable, Sendable {
    case pass = -1
    case none = 0
    case sip = 1
    case savor = 2

    public var displayName: String {
        switch self {
        case .pass: "Pass"
        case .none: "No Rating"
        case .sip: "Sip"
        case .savor: "Savor"
        }
    }

    public var emoji: String {
        switch self {
        case .pass: "👎"
        case .none: ""
        case .sip: "👍"
        case .savor: "👍👍"
        }
    }

    public var description: String {
        switch self {
        case .pass: "Not my thing"
        case .none: "No rating"
        case .sip: "Enjoyable, would drink again"
        case .savor: "Amazing, would seek out"
        }
    }

    public var iconCount: Int {
        self == .savor ? 2 : 1
    }

    public init?(rating: Double) {
        guard rating.rounded() == rating else { return nil }
        self.init(rawValue: Int(rating))
    }
}

public extension Operations.createTasting.Input.Body.jsonPayload {
    static func makeRating(_ value: RatingValue) -> ratingPayload? {
        guard value != .none else { return nil }

        // The anyOf is generated as value1, value2, value3
        // We need to determine which one to use based on the actual const values
        switch value.rawValue {
        case -1:
            return ratingPayload(
                value1: OpenAPIValueContainer(-1),
                value2: nil,
                value3: nil
            )
        case 1:
            return ratingPayload(
                value1: nil,
                value2: OpenAPIValueContainer(1),
                value3: nil
            )
        case 2:
            return ratingPayload(
                value1: nil,
                value2: nil,
                value3: OpenAPIValueContainer(2)
            )
        default:
            return nil
        }
    }
}

/// Helper to extract rating from API response
public func extractRating(from ratingPayload: (some Any)?) -> Double {
    guard let ratingPayload else { return 0.0 }

    // Use reflection to find the actual value
    let mirror = Mirror(reflecting: ratingPayload)

    for child in mirror.children {
        if let container = child.value as? OpenAPIValueContainer {
            if let intValue = container.value as? Int {
                return Double(intValue)
            }
            if let doubleValue = container.value as? Double {
                return doubleValue
            }
        }
    }

    return 0.0
}
