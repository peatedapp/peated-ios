# Color System (Cream Theme)

This app uses a semantic, token‑based color system optimized for a light cream theme, with future‑proofed dark variants.

Tokens (use these in SwiftUI via `Color.<token>`):

- Brand
  - `brand` — primary brand color (brown)
  - `brandEmphasis` — darker brand for pressed/selected states
  - `onBrand` — text/icon color to use on `brand`

- Surfaces
- `background` — app background (cream)
  - `surface` — elevated card surfaces
  - `surfaceSubtle` — subtle surface striping/tiles
  - `border` — separators, outlines

- Text
  - `text` — primary body text
  - `textSecondary` — secondary labels
  - `textMuted` — tertiary labels/hints
  - `onSurface` — text on surfaces if needed

- Overlays/Shadows
  - `overlaySoft` — light shadow/ink (15%)
  - `overlay` — medium overlay (30%)
  - `overlayStrong` — blocking overlay (60%)

- Status
  - `success`, `warning`, `danger`, `info`
  - `onStatus` — text/icon on any status color

Legacy aliases have been removed from code. Only use the semantic tokens above in app UI code and examples.

Usage guidance:

- Buttons on brand: background `brand`, foreground `onBrand`.
- Screens: background `bg`; cards: `surface` + `border` for outlines.
- Text: `text`, `textSecondary`; avoid hardcoded `.white`/`.black`.
- Shadows/overlays: prefer `overlay*` tokens instead of raw black opacities.

Swapping palettes:

- Implement a new `struct MyTheme: AppTheme` in `Peated/Peated/Common/Theming/Theme.swift` (or a sibling file) returning your colors.
- Set it at startup: `ThemeManager.shared.theme = MyTheme()` (e.g., in `AppView` `onAppear` or behind a developer setting).
- All `Color.<token>` usages resolve through `ThemeManager`, so the app picks up the palette without changing call sites.
