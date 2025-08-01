# Component Library

## Overview

This section documents all reusable UI components in the Peated iOS app. Each component is designed to be self-contained, testable, and follows SwiftUI best practices.

## Component Categories

### Core Components
- [TastingCard](tasting-card.md) - Main feed item showing a complete tasting
- [BottleRow](bottle-row.md) - Bottle search result or list item
- [RatingView](rating-view.md) - 5-star rating display and input
- [ToastButton](toast-button.md) - Social "like" interaction button
- [CommentView](comment-view.md) - Individual comment display

### Navigation Components
- [TabBar](navigation/tab-bar.md) - Custom tab bar with floating action button
- [FloatingButton](navigation/floating-button.md) - Floating "add tasting" button

### Input Components
- [SearchBar](search-bar.md) - Debounced search with suggestions
- [TagSelector](tag-selector.md) - Multi-select flavor tags
- [PhotoPicker](photo-picker.md) - Camera and library photo selection

### Display Components
- [UserAvatar](user-avatar.md) - Circular user profile image
- [BottleImage](bottle-image.md) - Bottle image with placeholder
- [LoadingView](loading-view.md) - Consistent loading states
- [EmptyStateView](empty-state-view.md) - Empty content messages

## Component Standards

### Design Principles

1. **Composability**: Components should be small and focused
2. **Customization**: Support common variations via parameters
3. **Accessibility**: Full VoiceOver and Dynamic Type support
4. **Performance**: Optimize for smooth scrolling and animations

### Component Structure

```swift
struct ComponentName: View {
    // MARK: - Properties
    let requiredProperty: Type
    var optionalProperty: Type = defaultValue
    
    // MARK: - State
    @State private var internalState: Type = defaultValue
    
    // MARK: - Body
    var body: some View {
        // Component implementation
    }
    
    // MARK: - Subviews
    @ViewBuilder
    private var subviewName: some View {
        // Subview implementation
    }
}

// MARK: - Previews
#Preview("Default") {
    ComponentName(requiredProperty: .example)
}

#Preview("Variation") {
    ComponentName(
        requiredProperty: .example,
        optionalProperty: .custom
    )
}
```

### Naming Conventions

- **Views**: PascalCase ending with `View` (e.g., `TastingCardView`)
- **Buttons**: PascalCase ending with `Button` (e.g., `ToastButton`)
- **Modifiers**: camelCase starting with verb (e.g., `cardStyle()`)
- **Environment Values**: camelCase (e.g., `tastingCardStyle`)

### State Management

Components should be as stateless as possible:
- Accept data via parameters
- Use callbacks for user interactions
- Internal state only for UI-specific needs
- No business logic or API calls

### Styling

```swift
// Define reusable styles
extension View {
    func cardStyle() -> some View {
        self
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, y: 2)
    }
}

// Use semantic colors
extension Color {
    static let peatedBrown = Color("PeatedBrown")
    static let toastGold = Color("ToastGold")
    static let whiskyAmber = Color("WhiskyAmber")
}
```

### Accessibility

All components must support:
- VoiceOver labels and hints
- Dynamic Type scaling
- Increased contrast mode
- Reduce motion preferences

```swift
struct AccessibleComponent: View {
    var body: some View {
        Button(action: {}) {
            Image(systemName: "heart")
        }
        .accessibilityLabel("Toast this tasting")
        .accessibilityHint("Double tap to like")
        .accessibilityAddTraits(.isButton)
    }
}
```

### Testing

Each component should have:
- Unit tests for logic
- Snapshot tests for visual regression
- Accessibility audit tests
- Performance tests for lists

```swift
class ComponentTests: XCTestCase {
    func testComponentRendersCorrectly() {
        let view = ComponentName(property: .mock)
        assertSnapshot(matching: view, as: .image)
    }
    
    func testAccessibility() {
        let view = ComponentName(property: .mock)
        XCTAssertTrue(view.isAccessible)
    }
}
```

## Component Documentation Template

Each component documentation should include:

1. **Overview**: What the component does
2. **Visual Example**: ASCII art or screenshot
3. **Usage**: Code examples
4. **Properties**: All parameters explained
5. **Variations**: Different states/styles
6. **Accessibility**: VoiceOver behavior
7. **Performance**: Any considerations
8. **Related**: Links to similar components