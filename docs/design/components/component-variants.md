# Component Variants System

## Overview

Components in Peated iOS support variants to adapt their display based on context while maintaining a single source of truth for styling and behavior.

## TastingFeedCard Variants

The primary component supporting variants is `TastingFeedCard`, which displays tasting entries throughout the app.

### Usage

```swift
// Full variant (shows bottle info) - Default
TastingFeedCard(
  tasting: tasting,
  showBottle: true,  // optional, defaults to true
  onToast: { /* action */ },
  onComment: { /* action */ },
  onUserTap: { /* action */ },
  onBottleTap: { /* action */ }
)

// Compact variant (hides bottle info)
TastingFeedCard(
  tasting: tasting,
  showBottle: false,
  onToast: { /* action */ },
  onComment: { /* action */ },
  onUserTap: { /* action */ },
  onBottleTap: { /* action */ }
)
```

### When to Use Each Variant

| Context | Variant | Reason |
|---------|---------|--------|
| Feed Views | `showBottle: true` | Users need bottle context |
| Search Results | `showBottle: true` | Bottle info is primary |
| Profile Tastings | `showBottle: true` | Shows what user tasted |
| Bottle Detail | `showBottle: false` | Bottle info is redundant |
| Tasting Detail | `showBottle: false` | Focus on tasting content |

## Benefits

1. **Single Source of Truth**: One component definition for all tasting displays
2. **Consistent Styling**: Changes propagate to all uses automatically
3. **Context Awareness**: Components adapt to their environment
4. **Maintainability**: Fewer components to maintain and test
5. **Flexibility**: Easy to add new variants without breaking existing uses

## Implementation Pattern

```swift
struct MyComponent: View {
  // Configuration
  let data: DataModel
  let variant: Variant
  
  // Callbacks
  let onAction: () -> Void
  
  // Default initializer
  init(
    data: DataModel,
    variant: Variant = .default,
    onAction: @escaping () -> Void
  ) {
    self.data = data
    self.variant = variant
    self.onAction = onAction
  }
  
  var body: some View {
    // Conditional rendering based on variant
    if variant.showsDetail {
      DetailView()
    }
  }
}
```

## Future Variant Opportunities

### BottleRow Variants
- `.compact` - Single line for dense lists
- `.detailed` - Shows rating and metadata
- `.selectable` - Shows checkmark when selected

### ProfileHeader Variants
- `.minimal` - Just avatar and name
- `.full` - Complete stats and bio
- `.editable` - Shows edit buttons

## Guidelines

1. **Default to Most Common**: The default variant should be the most frequently used
2. **Named Parameters**: Use clear boolean or enum parameters for variants
3. **Document Context**: Clearly document when each variant should be used
4. **Test All Variants**: Ensure each variant is tested in its intended context
5. **Avoid Over-Engineering**: Only add variants when there's a clear use case

## Migration Strategy

When adding variants to existing components:

1. Add optional parameter with default value
2. Update existing uses only where needed
3. Document the new variant
4. Add tests for new behavior
5. Deprecate old components if replaced