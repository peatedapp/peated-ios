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
                            .foregroundColor(.textSecondary)
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
                        
                        // Pass/Sip/Savor Rating
                        HStack(spacing: 12) {
                            // Pass button
                            RatingButton(
                                title: "Pass",
                                iconName: "hand.thumbsdown.fill",
                                value: -1,
                                selectedValue: $viewModel.rating,
                                color: .danger
                            )
                            
                            // Sip button
                            RatingButton(
                                title: "Sip",
                                iconName: "hand.thumbsup.fill",
                                value: 1,
                                selectedValue: $viewModel.rating,
                                color: .info
                            )
                            
                            // Savor button
                            RatingButton(
                                title: "Savor",
                                iconName: "hands.sparkles.fill",
                                value: 2,
                                selectedValue: $viewModel.rating,
                                color: .success
                            )
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Rating description
                        if viewModel.rating != 0 {
                            Text(ratingDescription)
                                .font(.subheadline)
                                .foregroundColor(.textSecondary)
                                .transition(.opacity)
                        }
                    }
                    
                    // Notes Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tasting Notes")
                            .font(.headline)
                        
                        Text("What did you taste? (Optional)")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                        
                        TextArea(
                            label: nil,
                            placeholder: "Describe the aroma, taste, and finish...",
                            text: $viewModel.notes,
                            minHeight: 120
                        )
                        .focused($isNotesFocused)
                        
                        // Character count
                        HStack {
                            Spacer()
                            Text("\(viewModel.notes.count)/500")
                                .font(.caption)
                                .foregroundColor(viewModel.notes.count > 500 ? .danger : .textSecondary)
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
                            .foregroundColor(.textSecondary)
                        
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
        case -1:
            return "Pass - Not to your taste"
        case 1:
            return "Sip - Worth trying, decent dram"
        case 2:
            return "Savor - Exceptional, highly recommended"
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
                    .foregroundColor(isSelected ? .onBrand : .brand)
                
                Text(style.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .onBrand : .text)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.brand : Color.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.brand : Color.clear, lineWidth: 2)
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
                .foregroundColor(isSelected ? .onBrand : .text)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isSelected ? Color.brand : Color.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.brand.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1.0)
    }
}

// MARK: - Rating Button
struct RatingButton: View {
    let title: String
    let iconName: String
    let value: Double
    @Binding var selectedValue: Double
    let color: Color
    
    private var isSelected: Bool {
        selectedValue == value
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                selectedValue = selectedValue == value ? 0 : value
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }) {
            VStack(spacing: 8) {
                if value == 2 {
                    // Show two thumbs up for Savor
                    HStack(spacing: 2) {
                        Image(systemName: "hand.thumbsup.fill")
                            .font(.system(size: 20))
                            .foregroundColor(isSelected ? color : .textSecondary)
                        Image(systemName: "hand.thumbsup.fill")
                            .font(.system(size: 20))
                            .foregroundColor(isSelected ? color : .textSecondary)
                    }
                } else {
                    Image(systemName: iconName)
                        .font(.system(size: 28))
                        .foregroundColor(isSelected ? color : .textSecondary)
                }
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color.opacity(0.2) : Color.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? color : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1.0)
    }
}
