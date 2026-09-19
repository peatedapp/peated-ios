import Foundation

/// A published review from an external site, shown with its own score scale.
public struct CriticReviewFeedItem: Identifiable, Hashable, Sendable {
    /// The score as the publication displays it. Only a 100-point scale maps to a Peated band.
    public struct Score: Hashable, Sendable {
        public let value: Double
        public let scale: Double
        public let display: String

        public init(value: Double, scale: Double, display: String) {
            self.value = value
            self.scale = scale
            self.display = display
        }

        public var ratingBand: TastingRatingBand? {
            guard scale == 100, value.rounded() == value else { return nil }
            return TastingRatingBand(score: Int(value))
        }
    }

    public let id: String
    public let url: String
    /// The publication name, or the reviewer when the site is unknown.
    public let sourceName: String
    public let sourceImageUrl: String?
    /// Set only when the reviewer differs from the source.
    public let byline: String?
    public let excerpt: String?
    public let score: Score?
    public let tags: [String]
    public let createdAt: Date

    public let bottle: ActivityBottleSummary

    public init(
        id: String,
        url: String,
        sourceName: String,
        sourceImageUrl: String?,
        byline: String?,
        excerpt: String?,
        score: Score?,
        tags: [String],
        createdAt: Date,
        bottle: ActivityBottleSummary
    ) {
        self.id = id
        self.url = url
        self.sourceName = sourceName
        self.sourceImageUrl = sourceImageUrl
        self.byline = byline
        self.excerpt = excerpt
        self.score = score
        self.tags = tags
        self.createdAt = createdAt
        self.bottle = bottle
    }
}
