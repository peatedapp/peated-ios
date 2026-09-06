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
}
