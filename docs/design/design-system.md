# Peated Design System

## Overview

This document records the design system used by the Peated iOS app. The shared design guide is `../peated/DESIGN.md`, and the exact web colors and measurements are in `../peated/apps/web/src/styles/tokens.stylex.ts` and `foundations.stylex.ts`. Follow @docs/how-to/sync-peated-upstream.md before changing the app-wide styles or updating screens.

The iOS app follows that shared guide. If this document or the Swift styles disagree with it, update the iOS styles and this document together. UI code must use the named theme colors and font roles below instead of values written directly in a screen.

Last synced with `peated` commit `ca4bf1bc1785017cb020c62f731742e92a5cab77` (2026-09-18).

Peated is a whisky database first: a reference work with community data, not a social feed. Keep chrome quiet, prefer useful density over decorative space, let real data provide character, and treat missing data as a normal state. Never add decorative eyebrow or kicker labels above headings.

## Where the tokens live

| Concern | File |
| --- | --- |
| Color tokens and the light and dark palettes | `Peated/Peated/Common/Theming/Theme.swift` |
| `Color.<token>` accessors and `Color.tastingCategory(named:)` | `Peated/Peated/Common/Extensions/Color+Peated.swift` |
| Font roles and bundled font names | `Peated/Peated/Common/Extensions/Font+Peated.swift` |
| Spacing, radii, tracking, control heights, and shared modifiers | `Peated/Peated/Common/DesignSystem.swift` |
| Font files and their licenses | `Peated/Peated/Resources/Fonts/` |
| Font registration | `UIAppFonts` in `Peated/Configuration/Info.plist` |
| System tint (links, toggles, bar buttons) | `Resources/Assets.xcassets/AccentColor.colorset` |

## Colors

Colors resolve through `ThemeManager` and the `AppTheme` protocol. Every token has a light and a dark value. Use `Color.<token>` in SwiftUI.

| iOS token | Web token | Light | Dark | Use |
| --- | --- | --- | --- | --- |
| `background` | `ground` | `#F7F8F5` | `#101210` | Screen background |
| `surface` | `surface` | `#EBEEE7` | `#1B1E1A` | Deliberate groups and overlays |
| `surfaceSubtle`, `formSurface` | `inset` | `#DCE0D6` | `#2B2F29` | Fields and neutral tracks |
| `surfaceSunken`, `ratingTrack` | `sunken`, `ratingTrack` | `#CBD0C2` | `#3A3F37` | Rating tracks on tonal surfaces |
| `imageBackground` | `imageBackground` | `#FFFFFF` | `#FFFFFF` | Catalog image canvas |
| `text`, `onSurface` | `ink` | `#161914` | `#E8EAE3` | Main text and committed actions |
| `textSecondary` | `inkMuted` | `#4B4E48` | `#B2B4AE` | Secondary text and metadata (opaque equivalent of 75% ink) |
| `textMuted` | | `#5B5E58` | `#A0A29D` | Tertiary hints |
| `brand` | `accent` | `#9A5B12` | `#D9922F` | Active state, links, ratings, and the one main action |
| `brandEmphasis` | `accentDeep` | `#6E400C` | `#E8A752` | Accent text on a tint, pressed states |
| `brandTint` | `accentTint` | 15% accent | 15% accent | Selected and related data |
| `onBrand` | | `ground` | `ground` | Text on `brand` |
| `dataAccent` | `dataAccent` | 42% accent | 42% accent | Secondary data fills |
| `ratingFill` | `ratingFill` | 75% accent | 75% accent | Compact rating distributions |
| `dataRange` | `dataRange` | 45% ink | 45% ink | Range lines in rating summaries |
| `passportEmpty` | `passportEmpty` | 16% ink | 16% ink | Unstamped passport cells |
| `border` | `hairline` | 11% ink | 11% ink | Dividers in repeated content |
| `sectionRule` | `sectionRule` | 16% ink | 16% ink | Page boundaries, chip and frame outlines |
| `formBorder` | `fieldRule` | 28% ink | 32% ink | Field outlines |
| `danger` | `critical` | `#A3231A` | `#F0776B` | Errors and destructive actions |
| `dangerQuiet` | `criticalQuiet` | 42% critical | 42% critical | Quiet error fills |
| `overlayShadow` | `overlayShadow` | 16% ink | 55% black | Shadow color for floating overlays |
| `chrome` | | 95% ground | 95% ground | Navigation and tab bars |
| `overlaySoft`, `overlay`, `overlayStrong` | | 5%, 11%, 20% ink | 5%, 11%, 20% ink | Scrims |
| `success`, `warning` | | `brand` | `brand` | Kept for source compatibility; both resolve to the accent |
| `info` | | 75% ink | 75% ink | Informational text |
| `onStatus` | | white | `ground` | Text on a status fill |

Rules:

- Use one warm color for links, ratings, and main actions. Do not add another action color and do not use red and green to mean bad and good.
- Use `background` for screens. Add `surface` only when a bounded group or overlay needs a clear container. Do not use filled cards as the default section treatment.
- Use `border` between repeated rows and `sectionRule` for page boundaries and framed regions. A framed region has a complete four-sided border.
- Put catalog images on `imageBackground` with a complete frame in both appearances.
- Use `text`, `textSecondary`, and `textMuted` for content. Avoid `.white` and `.black`.
- Do not invent ad hoc tokens in features. Extend `AppTheme` and this document together.

### Tasting-note categories

Each tasting-note category has its own color. Use these colors only to connect the same category across the tasting wheel, note vocabulary, saved tags, and flavor charts: on category edges, complete borders around tags and selectors, and filled chart slices. Keep text and action states on the usual ink and accent colors. Do not use category colors for links, buttons, ratings, feedback, or tag backgrounds.

`Color.tastingCategory(named:)` maps the API's `tagCategory` raw value to a color and returns `nil` for unknown categories, which keep the neutral tag border.

| Category | Token | Light | Dark |
| --- | --- | --- | --- |
| Cereal | `categoryCereal` | `#AD6F0B` | `#E2A744` |
| Fruit | `categoryFruit` | `#9F2F50` | `#D86485` |
| Floral | `categoryFloral` | `#6F4A9B` | `#AA8CD0` |
| Smoke | `categorySmoke` | `#2C7089` | `#76A5B5` |
| Earthy | `categoryEarthy` | `#356B48` | `#75A181` |
| Sulfur | `categorySulfur` | `#707A16` | `#B3B65F` |
| Sweet | `categorySweet` | `#C06092` | `#E6A0C0` |
| Spice | `categorySpice` | `#BD4822` | `#DF7B58` |
| Wood | `categoryWood` | `#5C4437` | `#9A7660` |

### Appearance

The operating system chooses light or dark, as on the web. The app keeps no theme state of its own: `Info.plist` sets no `UIUserInterfaceStyle`, the status bar follows each screen, and navigation and tab bars resolve `chrome` and `text` dynamically. Do not force a color scheme on a screen. The only fixed colors are white catalog image canvases (`imageBackground`) and white text over photo scrims. Check every screen change in both appearances.

## Typography

The app bundles three open-licensed families. Their OFL license files sit beside the font files.

- **Hanken Grotesk** (Bold) is the display face for names, headings, and meaningful figures.
- **Karla** (Regular, Italic, SemiBold, Bold) is the reading face for prose, labels, controls, and member input.
- **IBM Plex Mono** (Regular, Medium) is only for rare values that must align as code-like data.

Use the `Font.peated*` roles. Each role scales with Dynamic Type relative to the system text style closest to its web size. Do not use the display face for body copy, and do not create page-specific heading sizes.

| Role | Font | Family and weight | Size | Web line height | Use |
| --- | --- | --- | --- | --- | --- |
| Page title | `peatedPageTitle` | Hanken Grotesk 700 | 40 | 0.95 | Catalog identities such as bottle and entity names |
| Compact page title | `peatedPageTitleCompact` | Hanken Grotesk 700 | 32 | 1.1 | Task screens such as search, sign-in, and settings |
| Section heading | `peatedSectionHeading` | Hanken Grotesk 700 | 20 | 1.2 | Every section heading, in every column |
| Row title | `peatedRowTitle` | Hanken Grotesk 700 | 18 | 1.25 | Standard catalog and activity rows |
| Compact row title | `peatedRowTitleCompact` | Hanken Grotesk 700 | 15 | 1.25 | Sidebars, search results, and typeahead rows |
| Prose | `peatedProse` | Karla 400 | 16 | 1.65 | Long descriptions, reviews, and tasting notes |
| Body | `peatedBody` | Karla 400 | 15 | 1.6 | Short interface copy. The default role |
| Input | `peatedInput` | Karla 400 | 16 | 1.45 | Text fields, on every screen |
| Interactive | `peatedInteractive` | Karla 600 | 15 | 1.2 | Buttons, tabs, and links |
| Compact interactive | `peatedInteractiveSmall` | Karla 600 | 13 | 1.3 | Small buttons and chips |
| Metadata | `peatedMetadata` | Karla 400 | 13 | 1.45 | Dates, counts, hints, and table headers |
| Field label | `peatedFieldLabel` | Karla 600 | 13 | 1.4 | Form labels and typeahead group names |
| Micro label | `peatedMicroLabel` | Karla 400 | 13 | 1.4 | Short data labels |
| Code | `peatedCode` | IBM Plex Mono 400 | 13 | 1.45 | Identifiers and aligned technical values |

Display roles pair their font with the matching `DesignSystem.Tracking` value:

```swift
Text(bottle.fullName)
    .font(.peatedPageTitle)
    .tracking(DesignSystem.Tracking.pageTitle)
```

Rules:

- Keep metadata at 13. Let it wrap or give the layout more room instead of shrinking it.
- Selected controls keep the same family and size. Show selection with weight, color, and the active indicator.
- Use `.monospacedDigit()` for aligned numbers. Use uppercase only for short data labels.
- Logos, avatar initials, numeric scores, and labels inside scaled diagrams may size to their geometry. Their owning component defines those sizes through `Font.custom(PeatedFontName.<face>, size:relativeTo:)` and `DesignSystem.FontSize`; they do not create new body or heading roles.
- Screens that still call `.font(.system(...))` or system text styles such as `.caption` predate this system. Move them to a role when you touch the screen.

## Spacing

The spacing scale uses 4-point steps. Prefer these values before adding a local exception.

| Constant | Value |
| --- | --- |
| `DesignSystem.Spacing.xSmall` | 4 |
| `DesignSystem.Spacing.small` | 8 |
| `DesignSystem.Spacing.medium` | 12 |
| `DesignSystem.Spacing.large`, `cardPadding`, `screenPadding` | 16 |
| `DesignSystem.Spacing.xLarge` | 24 |
| `DesignSystem.Spacing.xxLarge` | 32 |
| `DesignSystem.Spacing.xxxLarge` | 48 |

Start each screen on `background` and use spacing and type for hierarchy. Content must work at 320 points wide without horizontal scrolling.

## Shapes

- Controls and deliberately framed regions use `DesignSystem.CornerRadius.medium` (3).
- Chips, tags, image slots, and bar segments use `DesignSystem.CornerRadius.small` (2).
- Do not use pills or `Capsule`.
- Use one-edge rules only as real separators inside repeated content, tabs, menus, tables, or fixed chrome. Keep dividers between repeated rows and none after the last row.

## Controls

`DesignSystem.ControlHeight` provides 34, 44, and 44 points. Touch screens use 44 as the default; give every control in the same action row the same height. Every control needs visible pressed and disabled states. Use `brand` for one main action per view and tonal controls for secondary actions. Do not let button labels wrap.

## Elevation

Floating overlays such as menus, typeahead results, and dialogs are the only elements with a shadow. Use `overlayShadow()`, which applies the web's `0 18px 40px` shadow with `Color.overlayShadow`. Nothing else casts a shadow.

## Images and data

- Standard catalog, search, and selection rows share `DesignSystem.ImageSize.bottleThumb`. Activity rows may use `bottleLarge` for real photos.
- Personal tasting photos cover their frame. Catalog images contain the full bottle on a white canvas and are never cropped to a square.
- Missing images use a neutral frame with the bottle glyph at the standard visual size.
- State precise values. Do not replace known numbers with vague labels and do not invent totals or ranges in a view.

## Icons

Use SF Symbols. Give every icon-only control an accessibility label.

## Accessibility

- Support Dynamic Type everywhere. All font roles scale; do not opt out with fixed sizes outside rating geometry.
- Keep text at WCAG AA contrast against `background` and `surface` in both appearances.
- Preserve iOS navigation, safe areas, and 44-point touch targets instead of copying web interactions literally.
