import SwiftUI

extension Font {
    // Hanken Grotesk/Karla equivalents until the web font files are shipped in the app bundle.
    static let peatedLargeTitle = Font.system(size: 40, weight: .bold, design: .rounded)
    static let peatedTitle = Font.system(size: 32, weight: .bold, design: .rounded)
    static let peatedTitle2 = Font.system(size: 22, weight: .bold, design: .rounded)
    static let peatedTitle3 = Font.system(size: 20, weight: .bold, design: .rounded)
    static let peatedHeadline = Font.system(size: 17, weight: .semibold)
    static let peatedBody = Font.system(size: 17, weight: .regular)
    static let peatedCallout = Font.system(size: 16, weight: .regular)
    static let peatedSubheadline = Font.system(size: 15, weight: .regular)
    static let peatedFootnote = Font.system(size: 13, weight: .regular)
    static let peatedCaption = Font.system(size: 12, weight: .regular)
    static let peatedCaption2 = Font.system(size: 11, weight: .regular)

    // Kept as source-compatible names while adopting the new sans-serif display role.
    static let peatedDisplaySerif = Font.system(size: 24, weight: .bold, design: .rounded)
    static let peatedDisplaySerifLarge = Font.system(size: 32, weight: .bold, design: .rounded)
    static let peatedHeadlineSerif = Font.system(size: 18, weight: .bold, design: .rounded)

    /// Single semantic title for screen headers (Profile/Bottle/Entity)
    static let titlePrimary = Font.system(size: 22, weight: .bold, design: .rounded)

    /// Semantic alias for prominent names (bottles, entities, usernames)
    static let nameTitle = Font.system(size: 18, weight: .bold, design: .rounded)
}
