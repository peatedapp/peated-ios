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
        case manual
    }

    public let pendingImageId: String
    public let pendingImageUrl: String
    public let facts: [BottlePhotoFact]
    public let searchQuery: String
    public let manualBottleInput: CreateBottleInput?
    public let photoSuitabilityReason: String?
    public let outcome: Outcome

    public init(
        pendingImageId: String,
        pendingImageUrl: String,
        facts: [BottlePhotoFact],
        searchQuery: String,
        manualBottleInput: CreateBottleInput?,
        photoSuitabilityReason: String?,
        outcome: Outcome
    ) {
        self.pendingImageId = pendingImageId
        self.pendingImageUrl = pendingImageUrl
        self.facts = facts
        self.searchQuery = searchQuery
        self.manualBottleInput = manualBottleInput
        self.photoSuitabilityReason = photoSuitabilityReason
        self.outcome = outcome
    }
}

public struct BottlePhotoCreation: Equatable, Sendable {
    public let bottle: Bottle
    public let warnings: [String]

    public init(bottle: Bottle, warnings: [String] = []) {
        self.bottle = bottle
        self.warnings = warnings
    }
}
