import Foundation

public struct BottlePhotoFact: Equatable, Identifiable, Sendable {
    public let label: String
    public let value: String

    public var id: String {
        label
    }

    public init(label: String, value: String) {
        self.label = label
        self.value = value
    }
}

public struct BottlePhotoProposal: Equatable, Sendable {
    public let name: String
    public let brandName: String
    public let category: BottleCategory?
    public let statedAge: Int?
    public let abv: Double?

    public var fullName: String {
        [brandName, name]
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    public var createInput: CreateBottleInput {
        CreateBottleInput(
            name: name,
            brandName: brandName,
            category: category,
            statedAge: statedAge,
            abv: abv
        )
    }

    public init(
        name: String,
        brandName: String,
        category: BottleCategory? = nil,
        statedAge: Int? = nil,
        abv: Double? = nil
    ) {
        self.name = name
        self.brandName = brandName
        self.category = category
        self.statedAge = statedAge
        self.abv = abv
    }
}

public struct BottlePhotoIdentification: Equatable, Sendable {
    public enum Outcome: Equatable, Sendable {
        case matched(Bottle)
        case proposed(BottlePhotoProposal, createToken: String)
        /// The label has bottle details, but no existing bottle matched it.
        case notFound
        /// The label did not yield enough details to suggest a bottle.
        case unidentified
    }

    public let pendingImageId: String
    public let pendingImageUrl: String
    public let facts: [BottlePhotoFact]
    public let searchQuery: String
    public let manualBottleInput: CreateBottleInput?
    public let outcome: Outcome

    public init(
        pendingImageId: String,
        pendingImageUrl: String,
        facts: [BottlePhotoFact],
        searchQuery: String,
        manualBottleInput: CreateBottleInput?,
        outcome: Outcome
    ) {
        self.pendingImageId = pendingImageId
        self.pendingImageUrl = pendingImageUrl
        self.facts = facts
        self.searchQuery = searchQuery
        self.manualBottleInput = manualBottleInput
        self.outcome = outcome
    }
}

/// A generic step the server reports while it looks for the bottle.
public enum BottlePhotoLookupStep: Equatable, Sendable {
    case checkingPeated
    case checkingWeb
    case comparing
}

/// Progress sent while a photo is identified, before the final result.
///
/// The exact-reference fast path sends only `photo` and `labelRead`.
public enum BottlePhotoProgress: Equatable, Sendable {
    /// The photo is stored. Its pending image can attach to a tasting before
    /// the final result arrives.
    case photo(pendingImageId: String)
    /// The label has been read.
    case labelRead
    /// Up to five bottles already in Peated that may match. They arrive before
    /// the classifier decides, so the member can pick one early.
    case candidates([Bottle])
    case step(BottlePhotoLookupStep)
}

public struct BottlePhotoCreation: Equatable, Sendable {
    public let bottle: Bottle
    public let warnings: [String]

    public init(bottle: Bottle, warnings: [String] = []) {
        self.bottle = bottle
        self.warnings = warnings
    }
}
