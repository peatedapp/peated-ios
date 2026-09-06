# Peated Design System

## Overview

This document records the design system currently used by the Peated iOS app. The shared design guide is `../peated/DESIGN.md`, and the exact web colors and measurements are in `../peated/apps/web/src/styles/tokens.stylex.ts`. Follow @docs/how-to/sync-peated-upstream.md before changing the app-wide styles or updating screens.

The iOS app follows that shared guide. If this document or the Swift styles disagree with it, update the iOS styles and this document together. UI code must use named theme colors instead of color values written directly in a screen.

See the detailed token reference in docs/design/colors.md.

## Color System

Semantic color tokens are resolved through an `AppTheme` provider (ThemeManager). Use the names below in all UI code:

```swift
// Tokens (via Color.<token>)
// Brand
brand, brandEmphasis, onBrand
// Surfaces
background, surface, surfaceSubtle, border
// Text
text, textSecondary, textMuted, onSurface
// Overlays
overlaySoft, overlay, overlayStrong
// Status
success, warning, danger, info, onStatus
```

Rules:
- Use `background` for screen backgrounds; `surface`/`surfaceSubtle` for cards and list rows; `border` for separators/outlines.
- Use `text`, `textSecondary`, `textMuted` for content; avoid `.white` / `.black` directly.
- Buttons on brand use `background: .brand` and `foreground: .onBrand`.
- Status surfaces (error/warning/info/success) should use `onStatus` for text/icons.
- Use overlay tokens for shadows/overlays (e.g., scrims) — do not hand‑roll black/white opacities.
- Do not use `.brand` or platform semantic backgrounds in app UI; use tokens.
- Do not invent ad‑hoc tokens in features; extend the theme only in the design system.

Dark mode readiness:
- Tokens are resolved dynamically by the active theme. Our default theme targets light; dark values are in place for future enabling.

Theme swapping:
- Implement a new `AppTheme` and set `ThemeManager.shared.theme = MyTheme()` (e.g., in Developer Settings). No call site changes required.

### Examples

```swift
// CTA on brand
Button("Action") { ... }
  .foregroundColor(.onBrand)
  .padding(.vertical, 12)
  .frame(maxWidth: .infinity)
  .background(Color.brand)
  .cornerRadius(12)

// Card
RoundedRectangle(cornerRadius: 12)
  .fill(Color.surface)
  .overlay(
    RoundedRectangle(cornerRadius: 12)
      .stroke(Color.border.opacity(0.3), lineWidth: 1)
  )

// Inline emphasis
Text("Savor").foregroundColor(.brand)

// Overlay scrim
Color.overlayStrong.ignoresSafeArea()
```

## Typography

```swift
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
}
```

## Spacing

```swift
enum Spacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let lg: CGFloat = 16
    static let xl: CGFloat = 20
    static let xxl: CGFloat = 24
    static let xxxl: CGFloat = 32
}

// Usage
VStack(spacing: Spacing.md) {
    // Content
}
.padding(Spacing.lg)
```

## Corner Radius

```swift
enum CornerRadius {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 6
    static let md: CGFloat = 8
    static let lg: CGFloat = 12
    static let xl: CGFloat = 16
    static let full: CGFloat = .infinity
}
```

## Shadows

```swift
extension View {
    func peatedShadow(_ style: ShadowStyle = .medium) -> some View {
        self.shadow(
            color: style.color,
            radius: style.radius,
            x: style.x,
            y: style.y
        )
    }
}

enum ShadowStyle {
    case small
    case medium
    case large
    
    var color: Color { Color.overlay }
    
    var radius: CGFloat {
        switch self {
        case .small: return 2
        case .medium: return 4
        case .large: return 8
        }
    }
    
    var x: CGFloat { 0 }
    
    var y: CGFloat {
        switch self {
        case .small: return 1
        case .medium: return 2
        case .large: return 4
        }
    }
}
```

## Components

### Card Style

```swift
struct PeatedCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.surface)
            .cornerRadius(CornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(Color.border, lineWidth: 1)
            )
    }
}

extension View {
    func peatedCard() -> some View {
        self.modifier(PeatedCardModifier())
    }
}
```

### Button Styles

```swift
struct PeatedButtonStyle: ButtonStyle {
    enum Variant {
        case primary
        case secondary
        case ghost
    }
    
    let variant: Variant
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.peatedBody)
            .fontWeight(.medium)
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(background(for: configuration))
            .foregroundColor(foregroundColor)
            .cornerRadius(CornerRadius.md)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
    
    private func background(for configuration: Configuration) -> Color {
        let isPressed = configuration.isPressed
        switch variant {
        case .primary:
            return isPressed ? .brandEmphasis : .brand
        case .secondary:
            return isPressed ? .surface : .surface
        case .ghost:
            return .clear
        }
    }
    
    private var foregroundColor: Color {
        switch variant {
        case .primary:
            return .onBrand
        case .secondary, .ghost:
            return .text
        }
    }
}
```

## Icons

We use SF Symbols throughout the app. Key icon mappings:

```swift
enum PeatedIcons {
    // Tab Bar
    static let feedTab = "rectangle.stack"
    static let searchTab = "magnifyingglass"
    static let createTab = "plus.circle.fill"
    static let libraryTab = "books.vertical"
    static let profileTab = "person.circle"
    
    // Actions
    static let toast = "hands.clap"
    static let toastFilled = "hands.clap.fill"
    static let comment = "bubble.left"
    static let share = "square.and.arrow.up"
    
    // Ratings
    static let starEmpty = "star"
    static let starFilled = "star.fill"
    static let starHalf = "star.leadinghalf.filled"
    
    // Creation
    static let camera = "camera"
    static let photoLibrary = "photo"
    static let location = "mappin"
    static let tag = "tag"
    
    // Navigation
    static let back = "chevron.left"
    static let forward = "chevron.right"
    static let close = "xmark"
    static let more = "ellipsis"
}
```

## Animation Constants

```swift
enum Animation {
    static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
    static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
    static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
    static let bouncy = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.6)
}
```

## Theming Considerations

Peated uses a token‑based theme with a light “cream” default and dark‑mode values in place.

1. Always use semantic tokens (Color.brand, Color.text, Color.surface, etc.).
2. Ensure sufficient contrast; use `onBrand`/`onStatus` for text over color fills.
3. Consider elevation: use `surface`/`surfaceSubtle` and `border` for depth.
4. Avoid hardcoded `Color.white`/`Color.black` and platform accents in app UI.

## Accessibility

- Ensure text meets WCAG AA contrast ratios against `background`/`surface`.
- Provide clear focus indicators using `brand` outlines/fills as appropriate.
- Support Dynamic Type for all text.
- Include accessible labels for icons and dynamic content.

## Usage in Code

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Text("Welcome to Peated")
                .font(.peatedTitle)
                .foregroundColor(.text)
            
            Button("Get Started") {
                // Action
            }
            .buttonStyle(PeatedButtonStyle(variant: .primary))
        }
        .padding(Spacing.xl)
        .background(Color.background)
    }
}
```

This design system provides a consistent visual language that matches the Peated web experience while feeling native on iOS.
