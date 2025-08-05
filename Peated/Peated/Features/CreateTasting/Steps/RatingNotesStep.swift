import SwiftUI
import PeatedCore

struct RatingNotesStep: View {
    @ObservedObject var viewModel: CreateTastingViewModel
    @FocusState private var isNotesFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Rate your experience")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    if let bottle = viewModel.selectedBottle {
                        Text("How was the \(bottle.name)?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
                
                VStack(spacing: 24) {
                    // Rating Section
                    VStack(spacing: 16) {
                        Text("Rating")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        // Star Rating
                        HStack(spacing: 8) {
                            ForEach(1...5, id: \.self) { star in
                                Button(action: {
                                    withAnimation(.spring(response: 0.3)) {
                                        viewModel.rating = Double(star)
                                    }
                                    // Haptic feedback
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }) {
                                    Image(systemName: star <= Int(viewModel.rating) ? "star.fill" : "star")
                                        .font(.system(size: 32))
                                        .foregroundColor(star <= Int(viewModel.rating) ? .yellow : .gray)
                                }
                                .scaleEffect(star <= Int(viewModel.rating) ? 1.1 : 1.0)
                                .animation(.spring(response: 0.3), value: viewModel.rating)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Rating description
                        if viewModel.rating > 0 {
                            Text(ratingDescription)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .transition(.opacity)
                        }
                    }
                    
                    // Notes Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tasting Notes")
                            .font(.headline)
                        
                        Text("What did you taste? (Optional)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemBackground))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isNotesFocused ? Color.accentColor : Color.clear, lineWidth: 2)
                                )
                            
                            TextEditor(text: $viewModel.notes)
                                .focused($isNotesFocused)
                                .padding(12)
                                .background(Color.clear)
                                .frame(minHeight: 120)
                                .overlay(
                                    // Placeholder text
                                    Group {
                                        if viewModel.notes.isEmpty && !isNotesFocused {
                                            VStack {
                                                HStack {
                                                    Text("Describe the aroma, taste, and finish...")
                                                        .foregroundColor(.secondary)
                                                        .padding(.leading, 16)
                                                        .padding(.top, 20)
                                                    Spacer()
                                                }
                                                Spacer()
                                            }
                                        }
                                    }
                                )
                        }
                        
                        // Character count
                        HStack {
                            Spacer()
                            Text("\(viewModel.notes.count)/500")
                                .font(.caption)
                                .foregroundColor(viewModel.notes.count > 500 ? .red : .secondary)
                        }
                    }
                    
                    // Serving Style Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How did you drink it?")
                            .font(.headline)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                            ForEach(ServingStyle.allCases, id: \.self) { style in
                                ServingStyleButton(
                                    style: style,
                                    isSelected: viewModel.servingStyle == style,
                                    onTap: {
                                        withAnimation(.spring(response: 0.3)) {
                                            viewModel.servingStyle = viewModel.servingStyle == style ? nil : style
                                        }
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    }
                                )
                            }
                        }
                    }
                    
                    // Flavor Tags Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Flavor Tags")
                            .font(.headline)
                        
                        Text("What flavors did you detect? (Optional)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        FlavorTagsView(
                            selectedTags: $viewModel.selectedTags,
                            availableTags: flavorTags
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 100) // Space for navigation buttons
        }
        .scrollDismissesKeyboard(.interactively)
    }
    
    private var ratingDescription: String {
        switch Int(viewModel.rating) {
        case 1:
            return "Poor - Wouldn't recommend"
        case 2:
            return "Fair - Below average"
        case 3:
            return "Good - Average whisky"
        case 4:
            return "Very Good - Would drink again"
        case 5:
            return "Excellent - Outstanding whisky"
        default:
            return ""
        }
    }
    
    private var flavorTags: [String] {
        [
            "Sweet", "Spicy", "Smoky", "Fruity", "Floral",
            "Vanilla", "Caramel", "Honey", "Chocolate", "Coffee",
            "Oak", "Leather", "Tobacco", "Peat", "Sherry",
            "Citrus", "Apple", "Pear", "Berry", "Tropical",
            "Nutty", "Herbal", "Medicinal", "Maritime", "Earthy"
        ]
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
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .accentColor)
                
                Text(style.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .white : .primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1.0)
    }
    
    private var iconName: String {
        switch style {
        case .neat:
            return "wineglass"
        case .rocks:
            return "cube"
        case .water:
            return "drop"
        }
    }
}

// MARK: - Flavor Tags View
struct FlavorTagsView: View {
    @Binding var selectedTags: Set<String>
    let availableTags: [String]
    
    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
            ForEach(availableTags, id: \.self) { tag in
                FlavorTagButton(
                    tag: tag,
                    isSelected: selectedTags.contains(tag),
                    onTap: {
                        withAnimation(.spring(response: 0.3)) {
                            if selectedTags.contains(tag) {
                                selectedTags.remove(tag)
                            } else {
                                selectedTags.insert(tag)
                            }
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                )
            }
        }
    }
}

// MARK: - Flavor Tag Button
struct FlavorTagButton: View {
    let tag: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(tag)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color.accentColor : Color(.secondarySystemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1.0)
    }
}