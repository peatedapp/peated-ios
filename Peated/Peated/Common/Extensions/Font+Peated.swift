import SwiftUI

extension Font {
    // Use system fonts with custom sizing
    static let peatedLargeTitle = Font.system(size: 34, weight: .bold)
    static let peatedTitle = Font.system(size: 28, weight: .bold)
    static let peatedTitle2 = Font.system(size: 22, weight: .semibold)
    static let peatedTitle3 = Font.system(size: 20, weight: .semibold)
    static let peatedHeadline = Font.system(size: 17, weight: .semibold)
    static let peatedBody = Font.system(size: 17, weight: .regular)
    static let peatedCallout = Font.system(size: 16, weight: .regular)
    static let peatedSubheadline = Font.system(size: 15, weight: .regular)
    static let peatedFootnote = Font.system(size: 13, weight: .regular)
    static let peatedCaption = Font.system(size: 12, weight: .regular)
    static let peatedCaption2 = Font.system(size: 11, weight: .regular)

    // Display/Title styles using a serif design for prominent names (e.g., bottles)
    static let peatedDisplaySerif = Font.system(size: 24, weight: .regular, design: .serif)
    static let peatedDisplaySerifLarge = Font.system(size: 28, weight: .regular, design: .serif)
    static let peatedHeadlineSerif = Font.system(size: 17, weight: .semibold, design: .serif)

    /// Single semantic title for screen headers (Profile/Bottle/Entity)
    static let titlePrimary = Font.system(size: 22, weight: .semibold, design: .default)

    /// Semantic alias for prominent names (bottles, entities, usernames)
    static let nameTitle = Font.system(size: 17, weight: .semibold, design: .rounded)
}
