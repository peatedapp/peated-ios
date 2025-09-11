# TastingCard Component

## Overview

The TastingCard is the core component of the activity feed, displaying a complete tasting with user info, bottle details, rating, notes, photos, and social interactions. It's designed to be information-rich while maintaining visual hierarchy and performance.

## Visual Example

```
┌─────────────────────────────────────────┐
│ [Avatar] John Smith is drinking a       │ 
│          Macallan 18                    │
│          with @jane, @bob               │
│          @ The Whisky Bar • 2h ago      │
├─────────────────────────────────────────┤
│ [Bottle] Macallan 18 Year Old          │
│ [Image]  The Macallan • Scotch         │
│          43% ABV                        │
│                                         │
│          ★★★★☆ 4.25                    │
│                                         │
│ "Incredible nose of sherry and oak,     │
│  with a long, warming finish..."        │
│                                         │
│ [Sherry] [Oak] [Smooth]                 │
│                                         │
│ ┌─────┐ ┌─────┐ ┌─────┐ ┌─────┐      │
│ │Photo│ │Photo│ │Photo│ │Photo│       │
│ └─────┘ └─────┘ └─────┘ └─────┘      │
├─────────────────────────────────────────┤
│ 🥃 12 Toasts    💬 3 Comments          │
└─────────────────────────────────────────┘
```

## Usage

```swift
TastingCard(
    tasting: tasting,
    onToast: { tasting in
        // Handle toast action
    },
    onComment: { tasting in 
        // Navigate to comments
    },
    onProfile: { user in
        // Navigate to user profile
    },
    onBottle: { bottle in
        // Navigate to bottle detail
    }
)
```

## Implementation

```swift
struct TastingCard: View {
    // MARK: - Properties
    let tasting: Tasting
    var showFullNotes: Bool = false
    var onToast: ((Tasting) -> Void)?
    var onComment: ((Tasting) -> Void)?
    var onProfile: ((User) -> Void)?
    var onBottle: ((Bottle) -> Void)?
    var onLocation: ((Location) -> Void)?
    var onShare: ((Tasting) -> Void)?
    
    // MARK: - State
    @State private var isToasting = false
    @State private var showingOptions = false
    
    // MARK: - Body
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            
            Divider()
            
            bottleSection
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            
            if let notes = tasting.notes, !notes.isEmpty {
                notesSection(notes)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
            
            if !tasting.tags.isEmpty {
                tagsSection
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
            
            if !tasting.imageUrls.isEmpty {
                photoSection
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
            
            Divider()
            
            socialSection
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
    
    // MARK: - Header Section
    @ViewBuilder
    private var headerSection: some View {
        HStack(alignment: .top, spacing: 12) {
            // User Avatar
            Button {
                onProfile?(tasting.user!)
            } label: {
                UserAvatar(user: tasting.user!, size: 44)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                // Main attribution line
                HStack(spacing: 4) {
                    Text(tasting.user?.displayName ?? tasting.user?.username ?? "")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("is drinking a")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
                
                // Bottle name (tappable)
                Button {
                    onBottle?(tasting.bottle!)
                } label: {
                    Text(tasting.bottle?.name ?? "")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.accentColor)
                        .lineLimit(1)
                }
                .buttonStyle(.plain)
                
                // Tagged friends
                if !tasting.taggedFriends.isEmpty {
                    HStack(spacing: 4) {
                        Text("with")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        ForEach(tasting.taggedFriends.prefix(3)) { friend in
                            Button {
                                onProfile?(friend)
                            } label: {
                                Text("@\(friend.username)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.accentColor)
                            }
                            .buttonStyle(.plain)
                        }
                        
                        if tasting.taggedFriends.count > 3 {
                            Text("and \(tasting.taggedFriends.count - 3) others")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Location and time
                HStack(spacing: 4) {
                    if let location = tasting.location {
                        Button {
                            onLocation?(location)
                        } label: {
                            HStack(spacing: 2) {
                                Image(systemName: "mappin")
                                    .font(.system(size: 11))
                                Text(location.name)
                                    .font(.system(size: 14))
                            }
                            .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                        
                        Text("•")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Text(tasting.createdAt.relativeTime)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Options menu
            Menu {
                Button {
                    onShare?(tasting)
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                
                if tasting.user?.id == currentUserId {
                    Divider()
                    
                    Button(role: .destructive) {
                        // Handle delete
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } else {
                    Button {
                        // Handle report
                    } label: {
                        Label("Report", systemImage: "flag")
                    }
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .frame(width: 44, height: 44)
            }
        }
    }
    
    // MARK: - Bottle Section
    @ViewBuilder
    private var bottleSection: some View {
        HStack(spacing: 12) {
            // Bottle image
            BottleImage(bottle: tasting.bottle!, size: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(tasting.bottle?.name ?? "")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                
                HStack(spacing: 4) {
                    if let distillery = tasting.bottle?.distillery {
                        Text(distillery.name)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        
                        Text("•")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                    
                    Text(tasting.bottle?.category.displayName ?? "")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                if let abv = tasting.bottle?.abv {
                    Text("\(abv, specifier: "%.1f")% ABV")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .onTapGesture {
            onBottle?(tasting.bottle!)
        }
        
        // Rating
        HStack(spacing: 8) {
            RatingView(
                rating: tasting.rating,
                maxRating: 5,
                size: 20,
                spacing: 4
            )
            
            Text(String(format: "%.2f", tasting.rating))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.primary)
        }
        .padding(.top, 8)
    }
    
    // MARK: - Notes Section
    @ViewBuilder
    private func notesSection(_ notes: String) -> some View {
        Text(notes)
            .font(.system(size: 15))
            .foregroundColor(.primary)
            .lineLimit(showFullNotes ? nil : 3)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    // MARK: - Tags Section
    @ViewBuilder
    private var tagsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tasting.tags, id: \.self) { tag in
                    TagView(text: tag)
                }
            }
        }
    }
    
    // MARK: - Photo Section
    @ViewBuilder
    private var photoSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(tasting.imageUrls.enumerated()), id: \.offset) { index, url in
                    TastingPhotoThumbnail(
                        url: url,
                        index: index,
                        totalCount: tasting.imageUrls.count
                    )
                }
            }
        }
        .frame(height: 80)
    }
    
    // MARK: - Social Section
    @ViewBuilder
    private var socialSection: some View {
        HStack(spacing: 20) {
            // Toast button
            Button {
                handleToast()
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: tasting.hasToasted ? "hands.clap.fill" : "hands.clap")
                        .font(.system(size: 18))
                        .foregroundColor(tasting.hasToasted ? .toastGold : .secondary)
                        .scaleEffect(isToasting ? 1.2 : 1.0)
                    
                    Text("\(tasting.toastCount)")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text("Toasts")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            .disabled(isToasting)
            
            // Comment button
            Button {
                onComment?(tasting)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                    
                    Text("\(tasting.commentCount)")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text("Comments")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
    }
    
    // MARK: - Actions
    private func handleToast() {
        guard !isToasting else { return }
        
        isToasting = true
        
        // Haptic feedback
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        
        // Optimistic update
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            if tasting.hasToasted {
                tasting.toastCount -= 1
                tasting.hasToasted = false
            } else {
                tasting.toastCount += 1
                tasting.hasToasted = true
            }
        }
        
        // Call handler
        onToast?(tasting)
        
        // Reset animation state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isToasting = false
        }
    }
}
```

## Properties

| Property | Type | Required | Description |
|----------|------|----------|-------------|
| `tasting` | `Tasting` | Yes | The tasting data to display |
| `showFullNotes` | `Bool` | No | Whether to show full notes (default: false) |
| `onToast` | `(Tasting) -> Void` | No | Toast button tap handler |
| `onComment` | `(Tasting) -> Void` | No | Comment button tap handler |
| `onProfile` | `(User) -> Void` | No | User profile tap handler |
| `onBottle` | `(Bottle) -> Void` | No | Bottle detail tap handler |
| `onLocation` | `(Location) -> Void` | No | Location tap handler |
| `onShare` | `(Tasting) -> Void` | No | Share button tap handler |

## Variations

### Compact Mode
For list views with less vertical space:
```swift
TastingCard(tasting: tasting)
    .environment(\.tastingCardStyle, .compact)
```

### Detail Mode
For the full tasting detail screen:
```swift
TastingCard(
    tasting: tasting,
    showFullNotes: true
)
.environment(\.tastingCardStyle, .detail)
```

## Accessibility

- **VoiceOver**: Full narration of all content
- **Labels**: "John Smith is drinking Macallan 18, rated 4.25 stars"
- **Actions**: "Double tap to view bottle details"
- **Traits**: Buttons marked appropriately
- **Grouping**: Related elements grouped for easier navigation

## Performance Considerations

- Images lazy loaded with `AsyncImage`
- Heavy content (photos) only rendered when visible
- Efficient re-rendering with `Equatable` conformance
- Animations use `spring` for smooth 60fps

## Related Components

- [UserAvatar](user-avatar.md) - User profile images
- [BottleImage](bottle-image.md) - Bottle thumbnails
- [RatingView](rating-view.md) - Star ratings
- [TagView](tag-view.md) - Flavor tags
- [ToastButton](toast-button.md) - Standalone toast button