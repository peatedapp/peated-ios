import SwiftUI
import PeatedCore

struct RatingServingStep: View {
    @ObservedObject var viewModel: CreateTastingViewModel
    
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
                        
                        // Pass/Sip/Savor Rating
                        HStack(spacing: 12) {
                            // Pass button
                            RatingSelectionButton(
                                title: "Pass",
                                iconName: "hand.thumbsdown.fill",
                                value: -1,
                                selectedValue: $viewModel.rating,
                                color: .red
                            )
                            
                            // Sip button
                            RatingSelectionButton(
                                title: "Sip",
                                iconName: "hand.thumbsup.fill",
                                value: 1,
                                selectedValue: $viewModel.rating,
                                color: .blue
                            )
                            
                            // Savor button
                            RatingSelectionButton(
                                title: "Savor",
                                iconName: "hands.sparkles.fill",
                                value: 2,
                                selectedValue: $viewModel.rating,
                                color: .green
                            )
                        }
                        .frame(maxWidth: .infinity)
                        
                        // Rating description
                        if viewModel.rating != 0 {
                            Text(ratingDescription)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .transition(.opacity)
                        }
                    }
                    
                    // Color Picker Section
                    WhiskyColorPicker(selectedColor: $viewModel.color)
                    
                    // Serving Style Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How did you drink it?")
                            .font(.headline)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                            ForEach(ServingStyle.allCases, id: \.self) { style in
                                RatingServingStyleButton(
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
}

// MARK: - Serving Style Button
private struct RatingServingStyleButton: View {
    let style: ServingStyle
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .black : .accentColor)
                
                Text(style.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .black : .primary)
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

// MARK: - Rating Button
private struct RatingSelectionButton: View {
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
                Image(systemName: iconName)
                    .font(.system(size: 28))
                    .foregroundColor(isSelected ? color : .secondary)
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color.opacity(0.2) : Color(.secondarySystemBackground))
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