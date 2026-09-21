import SwiftUI

/// PostScript names of the font files shipped in `Resources/Fonts` and registered through
/// `UIAppFonts` in `Configuration/Info.plist`. Keep both lists in sync with this enum.
enum PeatedFontName {
    /// Hanken Grotesk 700: names, headings, and meaningful figures.
    static let display = "HankenGrotesk-Bold"
    /// Karla: prose, labels, controls, and member input.
    static let reading = "Karla-Regular"
    static let readingItalic = "Karla-Italic"
    static let readingSemiBold = "Karla-SemiBold"
    static let readingBold = "Karla-Bold"
    /// IBM Plex Mono: rare values that must align as code-like data.
    static let data = "IBMPlexMono-Regular"
    static let dataMedium = "IBMPlexMono-Medium"
}

/// Typography roles from `../peated/DESIGN.md`. Every role scales with Dynamic Type relative
/// to the system text style whose default size is closest to the web size.
extension Font {
    // MARK: Display (Hanken Grotesk 700)

    /// Catalog identities such as bottle and entity names. Web: 40–72px, 40px on narrow screens.
    static let peatedPageTitle = Font.custom(PeatedFontName.display, size: 40, relativeTo: .largeTitle)
    /// Task screens such as search, sign-in, and settings. Web: 32–40px.
    static let peatedPageTitleCompact = Font.custom(PeatedFontName.display, size: 32, relativeTo: .largeTitle)
    static let peatedSectionHeading = Font.custom(PeatedFontName.display, size: 20, relativeTo: .title3)
    static let peatedRowTitle = Font.custom(PeatedFontName.display, size: 18, relativeTo: .headline)
    /// Sidebars, search results, and typeahead rows.
    static let peatedRowTitleCompact = Font.custom(PeatedFontName.display, size: 15, relativeTo: .subheadline)

    // MARK: Reading (Karla)

    /// Long descriptions, reviews, and tasting notes.
    static let peatedProse = Font.custom(PeatedFontName.reading, size: 16, relativeTo: .body)
    /// Short interface copy. This is the default text role.
    static let peatedBody = Font.custom(PeatedFontName.reading, size: 15, relativeTo: .subheadline)
    /// Text fields stay at 16 on every screen.
    static let peatedInput = Font.custom(PeatedFontName.reading, size: 16, relativeTo: .body)
    /// Buttons, tabs, and links.
    static let peatedInteractive = Font.custom(PeatedFontName.readingSemiBold, size: 15, relativeTo: .subheadline)
    static let peatedInteractiveSmall = Font.custom(PeatedFontName.readingSemiBold, size: 13, relativeTo: .footnote)
    /// Dates, counts, hints, and table headers. Do not shrink metadata below 13 to fit.
    static let peatedMetadata = Font.custom(PeatedFontName.reading, size: 13, relativeTo: .footnote)
    static let peatedFieldLabel = Font.custom(PeatedFontName.readingSemiBold, size: 13, relativeTo: .footnote)
    static let peatedMicroLabel = Font.custom(PeatedFontName.reading, size: 13, relativeTo: .footnote)

    // MARK: Data (IBM Plex Mono)

    /// Identifiers and values that must align as code-like data.
    static let peatedCode = Font.custom(PeatedFontName.data, size: 13, relativeTo: .footnote)

    // MARK: Rating and score figures

    // Numeric scores and their labels size to their geometry inside rating components.
    static let peatedRatingLabelSmall = Font.custom(PeatedFontName.display, size: 13, relativeTo: .footnote)
    static let peatedRatingLabel = Font.custom(PeatedFontName.display, size: 16, relativeTo: .callout)
    static let peatedRatingLabelLarge = Font.custom(PeatedFontName.display, size: 20, relativeTo: .title3)
    static let peatedScoreValueSmall = Font.custom(PeatedFontName.display, size: 18, relativeTo: .headline)
        .monospacedDigit()
    static let peatedScoreValue = Font.custom(PeatedFontName.display, size: 26, relativeTo: .title).monospacedDigit()
    static let peatedScoreValueLarge = Font.custom(PeatedFontName.display, size: 36, relativeTo: .largeTitle)
        .monospacedDigit()
}
