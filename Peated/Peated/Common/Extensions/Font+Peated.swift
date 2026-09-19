import SwiftUI

extension Font {
    // Hanken Grotesk/Karla equivalents until the web font files are shipped in the app bundle.
    static let peatedLargeTitle = Font.system(.largeTitle, design: .rounded, weight: .bold)
    static let peatedTitle = Font.system(.title, design: .rounded, weight: .bold)
    static let peatedTitle2 = Font.system(.title2, design: .rounded, weight: .bold)
    static let peatedTitle3 = Font.system(.title3, design: .rounded, weight: .bold)
    static let peatedHeadline = Font.system(.headline, weight: .semibold)
    static let peatedBody = Font.system(.body)
    static let peatedCallout = Font.system(.callout)
    static let peatedSubheadline = Font.system(.subheadline)
    static let peatedFootnote = Font.system(.footnote)
    static let peatedCaption = Font.system(.caption)
    static let peatedCaption2 = Font.system(.caption2)

    // Kept as source-compatible names while adopting the new sans-serif display role.
    static let peatedDisplaySerif = Font.system(.title2, design: .rounded, weight: .bold)
    static let peatedDisplaySerifLarge = Font.system(.title, design: .rounded, weight: .bold)
    static let peatedHeadlineSerif = Font.system(.headline, design: .rounded, weight: .bold)

    /// Single semantic title for screen headers (Profile/Bottle/Entity)
    static let titlePrimary = Font.system(.title2, design: .rounded, weight: .bold)

    /// Semantic alias for prominent names (bottles, entities, usernames)
    static let nameTitle = Font.system(.headline, design: .rounded, weight: .bold)

    // Activity rows and ratings mirror the web foundations (row title 18, metadata 13, body 15).
    static let peatedRowTitle = Font.system(size: 18, weight: .bold, design: .rounded)
    static let peatedMetadata = Font.system(size: 13)
    static let peatedBodyText = Font.system(size: 15)
    static let peatedInteractiveSmall = Font.system(size: 13, weight: .semibold)
    static let peatedRatingLabelSmall = Font.system(size: 13, weight: .bold, design: .rounded)
    static let peatedRatingLabel = Font.system(size: 16, weight: .bold, design: .rounded)
    static let peatedRatingLabelLarge = Font.system(size: 20, weight: .bold, design: .rounded)
    static let peatedScoreValueSmall = Font.system(size: 18, weight: .bold, design: .rounded).monospacedDigit()
    static let peatedScoreValue = Font.system(size: 26, weight: .bold, design: .rounded).monospacedDigit()
    static let peatedScoreValueLarge = Font.system(size: 36, weight: .bold, design: .rounded).monospacedDigit()
}
