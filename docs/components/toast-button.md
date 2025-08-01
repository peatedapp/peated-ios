# ToastButton Component

## Overview

The ToastButton is the primary social interaction component, allowing users to "toast" (like) tastings. It features an animated whisky glass icon with haptic feedback and optimistic UI updates.

## Visual Examples

### Default State
```
┌─────────────────┐
│ 🥃 12 Toasts    │
└─────────────────┘
```

### Toasted State
```
┌─────────────────┐
│ 🥃 13 Toasts    │  (Gold color, filled icon)
└─────────────────┘
```

### Compact Mode
```
┌────┐
│ 🥃 │
│ 12 │
└────┘
```

## Usage

```swift
// Basic usage
ToastButton(
    count: tasting.toastCount,
    hasToasted: tasting.hasToasted,
    onTap: {
        // Handle toast action
    }
)

// Compact mode
ToastButton(
    count: tasting.toastCount,
    hasToasted: tasting.hasToasted,
    style: .compact,
    onTap: { /* ... */ }
)

// With custom colors
ToastButton(
    count: tasting.toastCount,
    hasToasted: tasting.hasToasted,
    activeColor: .orange,
    onTap: { /* ... */ }
)
```

## Implementation

```swift
import SwiftUI

struct ToastButton: View {
    // MARK: - Properties
    let count: Int
    let hasToasted: Bool
    var style: ToastButtonStyle = .standard
    var size: ToastButtonSize = .medium
    var activeColor: Color = .toastGold
    var inactiveColor: Color = .secondary
    var isEnabled: Bool = true
    var showCount: Bool = true
    var onTap: () -> Void
    
    // MARK: - State
    @State private var isAnimating = false
    @State private var scale: CGFloat = 1.0
    
    // MARK: - Computed Properties
    private var iconName: String {
        hasToasted ? "hands.clap.fill" : "hands.clap"
    }
    
    private var iconSize: CGFloat {
        switch size {
        case .small: return 16
        case .medium: return 20
        case .large: return 24
        }
    }
    
    private var fontSize: CGFloat {
        switch size {
        case .small: return 14
        case .medium: return 16
        case .large: return 18
        }
    }
    
    // MARK: - Body
    var body: some View {
        Button(action: handleTap) {
            Group {
                switch style {
                case .standard:
                    standardLayout
                case .compact:
                    compactLayout
                case .iconOnly:
                    iconOnlyLayout
                }
            }
            .scaleEffect(scale)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled || isAnimating)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Double tap to toast this tasting")
        .accessibilityAddTraits(.isButton)
    }
    
    // MARK: - Layouts
    @ViewBuilder
    private var standardLayout: some View {
        HStack(spacing: 6) {
            Image(systemName: iconName)
                .font(.system(size: iconSize))
                .foregroundColor(hasToasted ? activeColor : inactiveColor)
                .symbolEffect(
                    .bounce,
                    options: .speed(1.5),
                    isActive: isAnimating
                )
            
            if showCount {
                Text("\(count)")
                    .font(.system(size: fontSize, weight: .medium))
                    .foregroundColor(.primary)
                    .contentTransition(.numericText())
                
                Text("Toasts")
                    .font(.system(size: fontSize))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(hasToasted ? activeColor : Color.clear, lineWidth: 1)
                )
        )
    }
    
    @ViewBuilder
    private var compactLayout: some View {
        VStack(spacing: 4) {
            Image(systemName: iconName)
                .font(.system(size: iconSize))
                .foregroundColor(hasToasted ? activeColor : inactiveColor)
                .symbolEffect(
                    .bounce,
                    options: .speed(1.5),
                    isActive: isAnimating
                )
            
            if showCount {
                Text("\(count)")
                    .font(.system(size: fontSize - 2, weight: .medium))
                    .foregroundColor(.primary)
                    .contentTransition(.numericText())
            }
        }
        .frame(minWidth: 44, minHeight: 44)
    }
    
    @ViewBuilder
    private var iconOnlyLayout: some View {
        Image(systemName: iconName)
            .font(.system(size: iconSize))
            .foregroundColor(hasToasted ? activeColor : inactiveColor)
            .symbolEffect(
                .bounce,
                options: .speed(1.5),
                isActive: isAnimating
            )
            .frame(width: 44, height: 44)
            .background(
                Circle()
                    .fill(hasToasted ? activeColor.opacity(0.1) : Color.clear)
            )
    }
    
    // MARK: - Computed Properties
    private var accessibilityLabel: String {
        if hasToasted {
            return "Remove toast. \(count) toasts"
        } else {
            return "Toast this tasting. \(count) toasts"
        }
    }
    
    // MARK: - Actions
    private func handleTap() {
        guard !isAnimating else { return }
        
        // Start animation
        isAnimating = true
        
        // Haptic feedback
        if hasToasted {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        } else {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        
        // Scale animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            scale = 1.1
        }
        
        // Call handler
        onTap()
        
        // Reset animation state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                scale = 1.0
            }
            isAnimating = false
        }
    }
}

// MARK: - Supporting Types
enum ToastButtonStyle {
    case standard   // Full horizontal layout
    case compact    // Vertical layout
    case iconOnly   // Just the icon
}

enum ToastButtonSize {
    case small
    case medium
    case large
}

// MARK: - Color Extension
extension Color {
    static let toastGold = Color(red: 1.0, green: 0.84, blue: 0.0)
}

// MARK: - Preview Provider
#Preview("Standard") {
    VStack(spacing: 20) {
        ToastButton(
            count: 12,
            hasToasted: false,
            onTap: {}
        )
        
        ToastButton(
            count: 13,
            hasToasted: true,
            onTap: {}
        )
    }
    .padding()
}

#Preview("Compact") {
    HStack(spacing: 20) {
        ToastButton(
            count: 12,
            hasToasted: false,
            style: .compact,
            onTap: {}
        )
        
        ToastButton(
            count: 13,
            hasToasted: true,
            style: .compact,
            onTap: {}
        )
    }
    .padding()
}

#Preview("Icon Only") {
    HStack(spacing: 20) {
        ToastButton(
            count: 12,
            hasToasted: false,
            style: .iconOnly,
            showCount: false,
            onTap: {}
        )
        
        ToastButton(
            count: 13,
            hasToasted: true,
            style: .iconOnly,
            showCount: false,
            onTap: {}
        )
    }
    .padding()
}
```

## Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `count` | `Int` | Required | Number of toasts |
| `hasToasted` | `Bool` | Required | Whether current user has toasted |
| `style` | `ToastButtonStyle` | `.standard` | Layout style |
| `size` | `ToastButtonSize` | `.medium` | Button size |
| `activeColor` | `Color` | `.toastGold` | Color when toasted |
| `inactiveColor` | `Color` | `.secondary` | Color when not toasted |
| `isEnabled` | `Bool` | `true` | Whether button is enabled |
| `showCount` | `Bool` | `true` | Whether to show count |
| `onTap` | `() -> Void` | Required | Tap handler |

## Animations

### Tap Animation
1. **Haptic Feedback**: Light impact for toast, soft for un-toast
2. **Scale Effect**: Grows to 1.1x then back to 1.0x
3. **Icon Bounce**: SF Symbol bounce effect
4. **Number Transition**: Smooth numeric text transition

### State Change
- Color transitions smoothly between active/inactive
- Background fill fades in/out for icon-only style
- Border appears/disappears for standard style

## Accessibility

- **VoiceOver Label**: "Toast this tasting. 12 toasts" or "Remove toast. 13 toasts"
- **Hint**: "Double tap to toast this tasting"
- **Traits**: Marked as button
- **Value**: Announces count changes

## Performance Considerations

- Lightweight component with minimal state
- Animations use GPU-accelerated effects
- Haptic feedback is immediate
- No network calls (handled by parent)

## Usage Guidelines

### Do's
- Use optimistic UI updates for immediate feedback
- Provide haptic feedback on all interactions
- Show loading state if network is slow
- Use consistent colors across the app

### Don'ts
- Don't disable during network requests
- Don't remove the animation
- Don't make the tap target too small
- Don't hide the count without reason

## Related Components

- [TastingCard](tasting-card.md) - Contains ToastButton
- [CommentButton](comment-button.md) - Similar interaction pattern
- [FollowButton](follow-button.md) - Similar state toggle
- [RatingView](rating-view.md) - Another interaction component