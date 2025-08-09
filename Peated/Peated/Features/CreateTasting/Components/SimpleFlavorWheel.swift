import SwiftUI
import UIKit

// MARK: - Color Opacity Helper
extension Color {
    static let lightBlueBackground = Color(UIColor.systemBlue.withAlphaComponent(0.1))
    
    func withOpacity(_ opacity: Double) -> Color {
        switch self {
        case .orange:
            return Color(UIColor.systemOrange.withAlphaComponent(opacity))
        case .pink:
            return Color(UIColor.systemPink.withAlphaComponent(opacity))
        case .red:
            return Color(UIColor.systemRed.withAlphaComponent(opacity))
        case .brown:
            return Color(UIColor.systemBrown.withAlphaComponent(opacity))
        case .gray:
            return Color(UIColor.systemGray.withAlphaComponent(opacity))
        case .purple:
            return Color(UIColor.systemPurple.withAlphaComponent(opacity))
        case .indigo:
            return Color(UIColor.systemIndigo.withAlphaComponent(opacity))
        default:
            return Color(UIColor.systemBlue.withAlphaComponent(opacity))
        }
    }
}

// MARK: - Simplified Flavor Wheel Component
struct SimpleFlavorWheel: View {
    @Binding var selectedTags: Set<String>
    @State private var expandedCategory: String?
    
    let flavorCategories: [(category: String, emoji: String, color: Color, flavors: [String])] = [
        ("Sweet", "🍯", .orange, ["Honey", "Caramel", "Vanilla", "Toffee", "Butterscotch"]),
        ("Fruity", "🍎", .pink, ["Apple", "Pear", "Citrus", "Berry", "Tropical"]),
        ("Spicy", "🌶️", .red, ["Pepper", "Cinnamon", "Nutmeg", "Clove", "Ginger"]),
        ("Woody", "🪵", .brown, ["Oak", "Cedar", "Pine", "Char", "Toasted"]),
        ("Smoky", "💨", .gray, ["Peat", "Ash", "Tobacco", "Leather", "Campfire"]),
        ("Floral", "🌸", .purple, ["Rose", "Lavender", "Violet", "Jasmine", "Heather"]),
        ("Nutty", "🥜", .brown, ["Almond", "Walnut", "Hazelnut", "Pecan", "Marzipan"]),
        ("Other", "✨", .indigo, ["Maritime", "Medicinal", "Herbal", "Earthy", "Mineral"])
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Flavor Profile")
                    .font(.headline)
                
                Spacer()
                
                if !selectedTags.isEmpty {
                    Text("\(selectedTags.count) selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Category bubbles
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(flavorCategories, id: \.category) { item in
                    CategoryButton(
                        emoji: item.emoji,
                        name: item.category,
                        color: item.color,
                        isExpanded: expandedCategory == item.category,
                        hasSelection: selectedTags.contains { tag in
                            item.flavors.contains(tag)
                        }
                    ) {
                        withAnimation {
                            if expandedCategory == item.category {
                                expandedCategory = nil
                            } else {
                                expandedCategory = item.category
                            }
                        }
                    }
                }
            }
            
            // Expanded flavors
            if let expanded = expandedCategory,
               let categoryData = flavorCategories.first(where: { $0.category == expanded }) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(expanded)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation {
                                expandedCategory = nil
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Flavor tags
                    FlexibleView(data: categoryData.flavors, spacing: 8) { flavor in
                        SimpleFlavorTag(
                            name: flavor,
                            isSelected: selectedTags.contains(flavor),
                            color: categoryData.color
                        ) {
                            toggleFlavor(flavor)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                )
            }
            
            // Selected tags
            if !selectedTags.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Selected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button("Clear") {
                            selectedTags.removeAll()
                        }
                        .font(.caption)
                        .foregroundColor(.accentColor)
                    }
                    
                    FlexibleView(data: selectedTags.sorted(), spacing: 6) { tag in
                        HStack(spacing: 4) {
                            Text(tag)
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            Button(action: {
                                selectedTags.remove(tag)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.lightBlueBackground)
                        .cornerRadius(12)
                    }
                }
            }
        }
    }
    
    private func toggleFlavor(_ flavor: String) {
        withAnimation {
            if selectedTags.contains(flavor) {
                selectedTags.remove(flavor)
            } else {
                selectedTags.insert(flavor)
            }
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

// MARK: - Category Button
struct CategoryButton: View {
    let emoji: String
    let name: String
    let color: Color
    let isExpanded: Bool
    let hasSelection: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(hasSelection ? color.withOpacity(0.2) : color.withOpacity(0.1))
                        .overlay(
                            Circle()
                                .stroke(hasSelection ? color.withOpacity(0.8) : color.withOpacity(0.3), lineWidth: hasSelection ? 2 : 1)
                        )
                    
                    Text(emoji)
                        .font(.title2)
                }
                .frame(width: 60, height: 60)
                .scaleEffect(isExpanded ? 1.1 : 1.0)
                
                Text(name)
                    .font(.caption2)
                    .fontWeight(hasSelection ? .semibold : .regular)
                    .foregroundColor(hasSelection ? color : .primary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Simple Flavor Tag
struct SimpleFlavorTag: View {
    let name: String
    let isSelected: Bool
    let color: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(name)
                .font(.caption)
                .fontWeight(isSelected ? .semibold : .medium)
                .foregroundColor(isSelected ? textColorForBackground(color) : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? color : Color(.tertiarySystemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.clear : color.withOpacity(0.3), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }
    
    private func textColorForBackground(_ backgroundColor: Color) -> Color {
        // Use black text for light backgrounds (orange/yellow/pink tones)
        if backgroundColor == .orange || backgroundColor == .pink {
            return .black
        }
        return .white
    }
}

// MARK: - Flexible View (Simple Grid Layout)
struct FlexibleView<Data: Collection, Content: View>: View where Data.Element: Hashable {
    let data: Data
    let spacing: CGFloat
    let content: (Data.Element) -> Content
    
    var body: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 80), spacing: spacing)
        ], spacing: spacing) {
            ForEach(Array(data), id: \.self) { item in
                content(item)
            }
        }
    }
}