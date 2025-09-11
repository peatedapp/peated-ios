# Rating & Notes Step

## Overview

The second step of the tasting creation flow captures the core tasting experience: rating, tasting notes, flavor tags, and serving style. This step emphasizes the rating as the primary required element while making other details optional for a quick check-in.

## Visual Layout

```
┌─────────────────────────────────────────┐
│  ✕ Cancel          Check In (2/5)       │
├─────────────────────────────────────────┤
│                                         │
│  How was the Lagavulin 16?             │
│                                         │
│  ─────────────────────────────────      │
│                                         │
│  Rating                                 │
│                                         │
│     ★  ★  ★  ★  ☆                     │
│         (Tap to rate)                   │
│                                         │
│  ─────────────────────────────────      │
│                                         │
│  Tasting Notes (Optional)               │
│  ┌─────────────────────────────────┐   │
│  │ What did you think?              │   │
│  │                                  │   │
│  │                                  │   │
│  └─────────────────────────────────┘   │
│  0/500 characters                       │
│                                         │
│  ─────────────────────────────────      │
│                                         │
│  Flavor Tags (Optional)                 │
│                                         │
│  Suggested:                             │
│  [Smoky] [Peaty] [Maritime] [Oily]      │
│  [Vanilla] [Honey]                      │
│                                         │
│  All Tags:                              │
│  [Sweet] [Spicy] [Fruity] [Floral]     │
│  [Woody] [Nutty] [+ More]              │
│                                         │
│  Selected: Smoky, Peaty                 │
│                                         │
│  ─────────────────────────────────      │
│                                         │
│  How did you have it? (Optional)        │
│  [ Neat ]  [ Rocks ]  [ Water ]        │
│                                         │
├─────────────────────────────────────────┤
│  ← Back                    Continue →   │
└─────────────────────────────────────────┘
```

## Implementation

```swift
import SwiftUI

struct RatingNotesStep: View {
    @ObservedObject var viewModel: CreateTastingViewModel
    @State private var allTags: [String] = []
    @State private var suggestedTags: [String] = []
    @State private var showingAllTags = false
    @State private var notesCharacterCount = 0
    @FocusState private var isNotesFocused: Bool
    
    private let maxNotesLength = 500
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("How was the")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(viewModel.selectedBottle?.name ?? "")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.accentColor)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Rating section
                ratingSection
                
                Divider()
                    .padding(.horizontal)
                
                // Notes section
                notesSection
                
                Divider()
                    .padding(.horizontal)
                
                // Flavor tags section
                flavorTagsSection
                
                Divider()
                    .padding(.horizontal)
                
                // Serving style section
                servingStyleSection
                
                // Add padding for navigation buttons
                Color.clear.frame(height: 100)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .task {
            await loadTags()
        }
    }
    
    // MARK: - Rating Section
    @ViewBuilder
    private var ratingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rating")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                // Interactive rating stars
                HStack(spacing: 16) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: starImage(for: star))
                            .font(.system(size: 44))
                            .foregroundColor(starColor(for: star))
                            .onTapGesture {
                                setRating(Double(star))
                            }
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        updateRatingFromDrag(at: value.location, star: star)
                                    }
                            )
                    }
                }
                .padding(.horizontal)
                
                // Rating label
                if viewModel.rating > 0 {
                    Text(ratingLabel)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.rating)
                } else {
                    Text("Tap to rate")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    // MARK: - Notes Section
    @ViewBuilder
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tasting Notes")
                    .font(.headline)
                
                Text("(Optional)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            VStack(alignment: .trailing, spacing: 8) {
                ZStack(alignment: .topLeading) {
                    if viewModel.notes.isEmpty {
                        Text("What did you think?")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }
                    
                    TextEditor(text: $viewModel.notes)
                        .font(.body)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(minHeight: 100, maxHeight: 200)
                        .background(Color.clear)
                        .focused($isNotesFocused)
                        .onChange(of: viewModel.notes) { newValue in
                            // Limit character count
                            if newValue.count > maxNotesLength {
                                viewModel.notes = String(newValue.prefix(maxNotesLength))
                            }
                            notesCharacterCount = viewModel.notes.count
                        }
                }
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
                
                Text("\(notesCharacterCount)/\(maxNotesLength) characters")
                    .font(.caption)
                    .foregroundColor(notesCharacterCount > maxNotesLength * 0.9 ? .orange : .secondary)
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Flavor Tags Section
    @ViewBuilder
    private var flavorTagsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Flavor Tags")
                    .font(.headline)
                
                Text("(Optional)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            // Suggested tags
            if !suggestedTags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Suggested:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(suggestedTags, id: \.self) { tag in
                                TagChip(
                                    text: tag,
                                    isSelected: viewModel.selectedTags.contains(tag),
                                    isSuggested: true,
                                    onTap: {
                                        toggleTag(tag)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            
            // All tags
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("All Tags:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            showingAllTags.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: showingAllTags ? "chevron.up" : "chevron.down")
                                .font(.caption)
                            Text(showingAllTags ? "Show Less" : "Show More")
                                .font(.caption)
                        }
                        .foregroundColor(.accentColor)
                    }
                }
                .padding(.horizontal)
                
                if showingAllTags {
                    FlowLayout(spacing: 8) {
                        ForEach(allTags, id: \.self) { tag in
                            TagChip(
                                text: tag,
                                isSelected: viewModel.selectedTags.contains(tag),
                                isSuggested: false,
                                onTap: {
                                    toggleTag(tag)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(allTags.prefix(10), id: \.self) { tag in
                                TagChip(
                                    text: tag,
                                    isSelected: viewModel.selectedTags.contains(tag),
                                    isSuggested: false,
                                    onTap: {
                                        toggleTag(tag)
                                    }
                                )
                            }
                            
                            if allTags.count > 10 {
                                Button(action: {
                                    withAnimation {
                                        showingAllTags = true
                                    }
                                }) {
                                    Text("+ More")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.accentColor)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.accentColor.opacity(0.1))
                                        .cornerRadius(15)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            
            // Selected tags summary
            if !viewModel.selectedTags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Selected:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(Array(viewModel.selectedTags).joined(separator: ", "))
                        .font(.body)
                        .foregroundColor(.primary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.tertiarySystemBackground))
                .cornerRadius(8)
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Serving Style Section
    @ViewBuilder
    private var servingStyleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("How did you have it?")
                    .font(.headline)
                
                Text("(Optional)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            HStack(spacing: 12) {
                ForEach(ServingStyle.allCases, id: \.self) { style in
                    ServingStyleButton(
                        style: style,
                        isSelected: viewModel.servingStyle == style,
                        onTap: {
                            withAnimation {
                                viewModel.servingStyle = viewModel.servingStyle == style ? nil : style
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Helper Methods
    private func starImage(for star: Int) -> String {
        let filled = Double(star) <= viewModel.rating
        return filled ? "star.fill" : "star"
    }
    
    private func starColor(for star: Int) -> Color {
        let filled = Double(star) <= viewModel.rating
        return filled ? .yellow : .gray.opacity(0.3)
    }
    
    private func setRating(_ rating: Double) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            viewModel.rating = viewModel.rating == rating ? 0 : rating
        }
        
        // Haptic feedback
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    private func updateRatingFromDrag(at location: CGPoint, star: Int) {
        // Implement half-star rating if needed
        let fraction = location.x / 44.0
        let rating = Double(star - 1) + Double(fraction).clamped(to: 0...1)
        
        withAnimation(.interactiveSpring()) {
            viewModel.rating = rating.rounded(to: 0.5)
        }
    }
    
    private var ratingLabel: String {
        switch viewModel.rating {
        case 0..<1: return ""
        case 1..<2: return "Poor"
        case 2..<3: return "Fair"
        case 3..<4: return "Good"
        case 4..<5: return "Very Good"
        case 5: return "Excellent"
        default: return ""
        }
    }
    
    private func toggleTag(_ tag: String) {
        withAnimation {
            if viewModel.selectedTags.contains(tag) {
                viewModel.selectedTags.remove(tag)
            } else {
                viewModel.selectedTags.insert(tag)
            }
        }
        
        // Haptic feedback
        UISelectionFeedbackGenerator().selectionChanged()
    }
    
    private func loadTags() async {
        // Load all tags from API
        // Load suggested tags for the selected bottle
        
        // Mock data for now
        allTags = ["Sweet", "Spicy", "Fruity", "Floral", "Woody", "Nutty", "Herbal", "Mineral", "Salty", "Bitter", "Sour", "Umami", "Creamy", "Oily", "Dry", "Tannic"]
        
        suggestedTags = ["Smoky", "Peaty", "Maritime", "Oily", "Vanilla", "Honey"]
    }
}

// MARK: - Tag Chip
struct TagChip: View {
    let text: String
    let isSelected: Bool
    let isSuggested: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                if isSuggested && !isSelected {
                    Image(systemName: "sparkle")
                        .font(.caption2)
                }
                
                Text(text)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .medium)
            }
            .foregroundColor(isSelected ? .white : (isSuggested ? .accentColor : .primary))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Group {
                    if isSelected {
                        Color.accentColor
                    } else if isSuggested {
                        Color.accentColor.opacity(0.15)
                    } else {
                        Color(.secondarySystemBackground)
                    }
                }
            )
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(
                        isSelected ? Color.clear : (isSuggested ? Color.accentColor.opacity(0.3) : Color.clear),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Serving Style Button
struct ServingStyleButton: View {
    let style: ServingStyle
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: style.iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .accentColor)
                
                Text(style.displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : Color.accentColor.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Flow Layout
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: result.positions[index].x + bounds.minX,
                                     y: result.positions[index].y + bounds.minY),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var maxHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth, x > 0 {
                    x = 0
                    y += maxHeight + spacing
                    maxHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                maxHeight = max(maxHeight, size.height)
                x += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: y + maxHeight)
        }
    }
}

// MARK: - Extensions
extension ServingStyle {
    var iconName: String {
        switch self {
        case .neat: return "drop"
        case .rocks: return "cube"
        case .water: return "drop.circle"
        }
    }
}

extension Double {
    func rounded(to places: Double) -> Double {
        let divisor = pow(10.0, places.rounded())
        return (self * divisor).rounded() / divisor
    }
    
    func clamped(to range: ClosedRange<Double>) -> Double {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}
```

## Features

### Rating (Required)
- Large interactive stars
- Tap to rate (whole stars)
- Drag for precision (half stars)
- Visual feedback
- Clear rating labels
- Can tap same star to clear

### Tasting Notes (Optional)
- Multi-line text input
- 500 character limit
- Character counter
- Placeholder text
- Keyboard dismissal

### Flavor Tags (Optional)
- API-driven tag list
- Suggested tags for bottle
- Sparkle icon for suggestions
- Expand/collapse all tags
- Multiple selection
- Visual selection state
- Selected tags summary

### Serving Style (Optional)
- Neat, Rocks, Water options
- Icon representation
- Single selection
- Can deselect

## Data Flow

### Tag Loading
- Fetch all available tags from API
- Fetch suggested tags for specific bottle
- Cache for session
- Show loading state

### State Updates
- Rating updates enable Continue
- All other fields optional
- Real-time character count
- Tag selection feedback

## User Experience

### Visual Hierarchy
1. Rating - Most prominent
2. Notes - Secondary importance
3. Tags - Browse and select
4. Serving - Quick selection

### Interactions
- Haptic feedback on selections
- Smooth animations
- Clear optional indicators
- Keyboard avoidance

## Validation

### Required
- Rating > 0 to continue

### Optional
- Notes can be empty
- No tags required
- No serving style required

### Limits
- Notes: 500 characters
- Tags: No limit on selection
- Rating: 1-5 stars (0.5 increments)

## Accessibility

- VoiceOver support for all elements
- Rating announced as "X out of 5 stars"
- Tag selection state announced
- Character count announced
- Serving style clearly labeled

## Performance

- Lazy load tag lists
- Efficient tag filtering
- Smooth animations at 60fps
- Minimal re-renders