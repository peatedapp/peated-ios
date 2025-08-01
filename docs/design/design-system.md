# Peated Design System

## Overview

This document defines the design system for the Peated iOS app, based on the web application's visual identity. The app uses a dark theme with yellow/gold accents.

## Color Palette

### Primary Colors

```swift
extension Color {
    // Brand Colors
    static let peatedGold = Color(hex: "#fbbf24")          // Primary accent, toasts, ratings
    static let peatedGoldDark = Color(hex: "#f59e0b")      // Darker variant for pressed states
    
    // Background Colors (Dark Theme)
    static let peatedBackground = Color(hex: "#020617")     // Main background (slate-950)
    static let peatedSurface = Color(hex: "#0f172a")        // Elevated surfaces (slate-900)
    static let peatedSurfaceLight = Color(hex: "#1e293b")   // Cards, cells (slate-800)
    
    // Border Colors
    static let peatedBorder = Color(hex: "#334155")         // Default borders (slate-700)
    static let peatedBorderLight = Color(hex: "#475569")    // Hover/focus borders (slate-600)
    
    // Text Colors
    static let peatedTextPrimary = Color.white
    static let peatedTextSecondary = Color.white.opacity(0.7)
    static let peatedTextMuted = Color.white.opacity(0.5)
    
    // Semantic Colors
    static let peatedSuccess = Color(hex: "#10b981")        // Green for success
    static let peatedError = Color(hex: "#ef4444")          // Red for errors
    static let peatedWarning = Color(hex: "#f59e0b")        // Amber for warnings
    static let peatedInfo = Color(hex: "#3b82f6")           // Blue for info
}

// Helper extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
```

### Usage Examples

```swift
// Toast button
Image(systemName: hasToasted ? "hands.clap.fill" : "hands.clap")
    .foregroundColor(hasToasted ? .peatedGold : .peatedTextSecondary)

// Rating stars
Image(systemName: "star.fill")
    .foregroundColor(.peatedGold)

// Card background
RoundedRectangle(cornerRadius: 12)
    .fill(Color.peatedSurfaceLight)
    .overlay(
        RoundedRectangle(cornerRadius: 12)
            .stroke(Color.peatedBorder, lineWidth: 1)
    )
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
    
    var color: Color {
        Color.black.opacity(0.25)
    }
    
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
            .background(Color.peatedSurfaceLight)
            .cornerRadius(CornerRadius.lg)
            .overlay(
                RoundedRectangle(cornerRadius: CornerRadius.lg)
                    .stroke(Color.peatedBorder, lineWidth: 1)
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
            return isPressed ? .peatedGoldDark : .peatedGold
        case .secondary:
            return isPressed ? .peatedSurfaceLight : .peatedSurface
        case .ghost:
            return .clear
        }
    }
    
    private var foregroundColor: Color {
        switch variant {
        case .primary:
            return .black
        case .secondary, .ghost:
            return .peatedTextPrimary
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

## Dark Theme Considerations

Since Peated uses a dark theme exclusively:

1. **Always use semantic colors** - Don't hardcode black/white
2. **Ensure sufficient contrast** - Especially for muted text
3. **Test on OLED displays** - Pure blacks can cause smearing
4. **Consider elevation** - Use surface colors to show depth
5. **Avoid bright whites** - Use slightly off-white for less eye strain

## Accessibility

- Ensure all text meets WCAG AA contrast ratios against backgrounds
- Provide clear focus indicators using `.peatedGold`
- Support Dynamic Type for all text
- Include proper accessibility labels for icons

## Usage in Code

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: Spacing.lg) {
            Text("Welcome to Peated")
                .font(.peatedTitle)
                .foregroundColor(.peatedTextPrimary)
            
            Button("Get Started") {
                // Action
            }
            .buttonStyle(PeatedButtonStyle(variant: .primary))
        }
        .padding(Spacing.xl)
        .background(Color.peatedBackground)
    }
}
```

This design system provides a consistent visual language that matches the Peated web experience while feeling native on iOS.