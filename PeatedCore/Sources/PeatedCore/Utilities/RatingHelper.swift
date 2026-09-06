import Foundation
import PeatedAPI

public enum TastingRatingBand: String, CaseIterable, Codable, Hashable, Sendable {
    case mediocre
    case good
    case veryGood = "very_good"
    case outstanding
    case unicorn

    public var displayName: String {
        switch self {
        case .mediocre: "Mediocre"
        case .good: "Good"
        case .veryGood: "Very good"
        case .outstanding: "Outstanding"
        case .unicorn: "Unicorn"
        }
    }

    public var scoreRange: ClosedRange<Int> {
        switch self {
        case .mediocre: 0 ... 79
        case .good: 80 ... 84
        case .veryGood: 85 ... 89
        case .outstanding: 90 ... 94
        case .unicorn: 95 ... 100
        }
    }

    public var description: String {
        switch self {
        case .mediocre: "Below 80"
        case .good: "80–84"
        case .veryGood: "85–89"
        case .outstanding: "90–94"
        case .unicorn: "95–100"
        }
    }

    public init?(score: Int) {
        guard 0 ... 100 ~= score else { return nil }

        switch score {
        case ...79: self = .mediocre
        case 80 ... 84: self = .good
        case 85 ... 89: self = .veryGood
        case 90 ... 94: self = .outstanding
        default: self = .unicorn
        }
    }
}

public extension TastingRatingBand {
    init(_ payload: Components.Schemas.Tasting.ratingBandPayload) {
        switch payload {
        case .mediocre: self = .mediocre
        case .good: self = .good
        case .very_good: self = .veryGood
        case .outstanding: self = .outstanding
        case .unicorn: self = .unicorn
        }
    }

    var createPayload: Operations.createTasting.Input.Body.jsonPayload.ratingBandPayload {
        switch self {
        case .mediocre: .mediocre
        case .good: .good
        case .veryGood: .very_good
        case .outstanding: .outstanding
        case .unicorn: .unicorn
        }
    }
}
