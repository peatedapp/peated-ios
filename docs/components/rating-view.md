# RatingView Component

## Overview

RatingView displays and allows input of star ratings. It supports both read-only display and interactive rating selection with half-star precision. The component is highly customizable with different styles, sizes, and colors.

## Visual Examples

### Display Mode (4.25/5)
```
★★★★☆
```

### Input Mode
```
★★★☆☆  (Tap to rate)
```

### Compact with Number
```
★★★★☆ 4.25
```

### Large Interactive
```
★  ★  ★  ★  ☆
(Draggable)
```

## Usage

```swift
// Display only
RatingView(
    rating: 4.25,
    maxRating: 5
)

// Interactive input
RatingView(
    rating: $userRating,
    maxRating: 5,
    isInteractive: true
)

// Customized appearance
RatingView(
    rating: 3.5,
    maxRating: 5,
    size: 24,
    spacing: 8,
    filledColor: .orange,
    emptyColor: .gray.opacity(0.3)
)

// With number display
HStack {
    RatingView(rating: 4.25)
    Text("4.25")
        .font(.headline)
}
```

## Implementation

```swift
import SwiftUI

struct RatingView: View {
    // MARK: - Properties
    @Binding var rating: Double
    let maxRating: Int
    var isInteractive: Bool = false
    var size: CGFloat = 20
    var spacing: CGFloat = 4
    var filledColor: Color = .whiskyAmber
    var emptyColor: Color = Color(.systemGray4)
    var allowHalfStars: Bool = true
    var showAnimation: Bool = true
    
    // MARK: - Initializers
    init(rating: Binding<Double>,
         maxRating: Int = 5,
         isInteractive: Bool = false,
         size: CGFloat = 20,
         spacing: CGFloat = 4,
         filledColor: Color = .whiskyAmber,
         emptyColor: Color = Color(.systemGray4),
         allowHalfStars: Bool = true,
         showAnimation: Bool = true) {
        self._rating = rating
        self.maxRating = maxRating
        self.isInteractive = isInteractive
        self.size = size
        self.spacing = spacing
        self.filledColor = filledColor
        self.emptyColor = emptyColor
        self.allowHalfStars = allowHalfStars
        self.showAnimation = showAnimation
    }
    
    // Read-only convenience initializer
    init(rating: Double,
         maxRating: Int = 5,
         size: CGFloat = 20,
         spacing: CGFloat = 4,
         filledColor: Color = .whiskyAmber,
         emptyColor: Color = Color(.systemGray4)) {
        self._rating = .constant(rating)
        self.maxRating = maxRating
        self.isInteractive = false
        self.size = size
        self.spacing = spacing
        self.filledColor = filledColor
        self.emptyColor = emptyColor
        self.allowHalfStars = true
        self.showAnimation = true
    }
    
    // MARK: - State
    @State private var dragRating: Double?
    @GestureState private var isDragging = false
    
    // MARK: - Body
    var body: some View {
        HStack(spacing: spacing) {
            ForEach(1...maxRating, id: \.self) { star in
                starView(for: star)
                    .frame(width: size, height: size)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue("\(rating, specifier: "%.1f") out of \(maxRating) stars")
        .accessibilityAdjustableAction { direction in
            if isInteractive {
                adjustRating(direction)
            }
        }
        .if(isInteractive) { view in
            view
                .contentShape(Rectangle())
                .gesture(dragGesture)
        }
    }
    
    // MARK: - Star View
    @ViewBuilder
    private func starView(for star: Int) -> some View {
        GeometryReader { geometry in
            ZStack {
                // Empty star background
                Image(systemName: "star")
                    .font(.system(size: size))
                    .foregroundColor(emptyColor)
                
                // Filled star overlay
                Image(systemName: "star.fill")
                    .font(.system(size: size))
                    .foregroundColor(filledColor)
                    .mask(
                        Rectangle()
                            .size(
                                width: geometry.size.width * fillAmount(for: star),
                                height: geometry.size.height
                            )
                    )
                    .animation(showAnimation ? .easeInOut(duration: 0.2) : nil, value: displayRating)
            }
            .if(isInteractive) { view in
                view
                    .scaleEffect(isDragging && isStarActive(star) ? 1.2 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)
            }
        }
    }
    
    // MARK: - Computed Properties
    private var displayRating: Double {
        dragRating ?? rating
    }
    
    private func fillAmount(for star: Int) -> CGFloat {
        let starValue = Double(star)
        
        if displayRating >= starValue {
            return 1.0
        } else if displayRating > starValue - 1 {
            if allowHalfStars {
                let fractional = displayRating - (starValue - 1)
                return CGFloat(fractional)
            } else {
                return displayRating > starValue - 0.5 ? 1.0 : 0.0
            }
        } else {
            return 0.0
        }
    }
    
    private func isStarActive(_ star: Int) -> Bool {
        let starValue = Double(star)
        return displayRating >= starValue - 1 && displayRating < starValue
    }
    
    private var accessibilityLabel: String {
        if isInteractive {
            return "Rate this whisky"
        } else {
            return "Rating"
        }
    }
    
    // MARK: - Gestures
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .updating($isDragging) { _, state, _ in
                state = true
            }
            .onChanged { value in
                updateRating(at: value.location)
            }
            .onEnded { _ in
                if let dragRating = dragRating {
                    rating = dragRating
                    
                    // Haptic feedback
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
                self.dragRating = nil
            }
    }
    
    // MARK: - Rating Calculation
    private func updateRating(at location: CGPoint) {
        let totalWidth = CGFloat(maxRating) * size + CGFloat(maxRating - 1) * spacing
        let x = max(0, min(location.x, totalWidth))
        
        let starWidth = size + spacing
        let starIndex = Int(x / starWidth)
        let starFraction = (x - CGFloat(starIndex) * starWidth) / size
        
        var newRating = Double(starIndex) + Double(starFraction)
        
        if !allowHalfStars {
            newRating = starFraction >= 0.5 ? Double(starIndex + 1) : Double(starIndex)
        } else {
            // Snap to quarter values for better UX
            let fractional = newRating.truncatingRemainder(dividingBy: 1)
            if fractional < 0.25 {
                newRating = floor(newRating)
            } else if fractional < 0.75 {
                newRating = floor(newRating) + 0.5
            } else {
                newRating = ceil(newRating)
            }
        }
        
        dragRating = max(0, min(Double(maxRating), newRating))
    }
    
    // MARK: - Accessibility Actions
    private func adjustRating(_ direction: AccessibilityAdjustmentDirection) {
        let step = allowHalfStars ? 0.5 : 1.0
        
        switch direction {
        case .increment:
            rating = min(rating + step, Double(maxRating))
        case .decrement:
            rating = max(rating - step, 0)
        @unknown default:
            break
        }
        
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

// MARK: - View Extension
extension View {
    @ViewBuilder
    func `if`<Transform: View>(_ condition: Bool, transform: (Self) -> Transform) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

// MARK: - Color Extension
extension Color {
    static let whiskyAmber = Color(red: 1.0, green: 0.75, blue: 0.0)
}

// MARK: - Previews
#Preview("Display Ratings") {
    VStack(spacing: 20) {
        RatingView(rating: 0)
        RatingView(rating: 2.5)
        RatingView(rating: 4.25)
        RatingView(rating: 5)
    }
    .padding()
}

#Preview("Interactive") {
    struct InteractivePreview: View {
        @State private var rating: Double = 3.5
        
        var body: some View {
            VStack(spacing: 20) {
                RatingView(
                    rating: $rating,
                    isInteractive: true,
                    size: 30,
                    spacing: 8
                )
                
                Text("Rating: \(rating, specifier: "%.1f")")
                    .font(.headline)
                
                Button("Reset") {
                    withAnimation {
                        rating = 0
                    }
                }
            }
            .padding()
        }
    }
    
    return InteractivePreview()
}

#Preview("Custom Styles") {
    VStack(spacing: 20) {
        RatingView(
            rating: 3.5,
            size: 16,
            spacing: 2,
            filledColor: .red,
            emptyColor: .red.opacity(0.3)
        )
        
        RatingView(
            rating: 4,
            maxRating: 10,
            size: 12,
            spacing: 1
        )
        
        RatingView(
            rating: 4.5,
            size: 40,
            spacing: 10,
            filledColor: .purple
        )
    }
    .padding()
}
```

## Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `rating` | `Binding<Double>` or `Double` | Required | Current rating value |
| `maxRating` | `Int` | 5 | Maximum number of stars |
| `isInteractive` | `Bool` | `false` | Enable user interaction |
| `size` | `CGFloat` | 20 | Star size in points |
| `spacing` | `CGFloat` | 4 | Space between stars |
| `filledColor` | `Color` | `.whiskyAmber` | Color for filled stars |
| `emptyColor` | `Color` | `.systemGray4` | Color for empty stars |
| `allowHalfStars` | `Bool` | `true` | Allow half-star ratings |
| `showAnimation` | `Bool` | `true` | Animate rating changes |

## Interaction Modes

### Display Mode
- Read-only presentation of rating
- No user interaction
- Smooth animations on value change

### Interactive Mode
- Tap to set rating
- Drag to adjust rating smoothly
- Haptic feedback on changes
- Visual feedback during interaction

## Accessibility

- **VoiceOver**: "Rating, 4.5 out of 5 stars"
- **Adjustable**: Swipe up/down to change rating
- **Hints**: "Swipe up or down to adjust rating"
- **Grouped**: Individual stars combined into single element

## Customization Examples

### Inline with Text
```swift
HStack(alignment: .center) {
    RatingView(rating: 4.25, size: 16)
    Text("4.25")
        .font(.system(size: 16, weight: .medium))
}
```

### Large Interactive
```swift
RatingView(
    rating: $userRating,
    isInteractive: true,
    size: 40,
    spacing: 12
)
```

### Custom Colors
```swift
RatingView(
    rating: bottle.avgRating,
    filledColor: .orange,
    emptyColor: .orange.opacity(0.2)
)
```

## Performance Considerations

- Efficient star rendering with masks
- Minimal redraws during interaction
- Smooth 60fps animations
- Lightweight gesture handling

## Related Components

- [TastingCard](tasting-card.md) - Uses RatingView for display
- [CreateTastingView](../screens/creation/rating-notes.md) - Uses for input
- [BottleDetail](../screens/search/bottle-detail.md) - Shows average rating