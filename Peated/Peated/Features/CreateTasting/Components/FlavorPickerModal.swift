import SwiftUI

struct FlavorPickerModal: View {
    @Binding var selectedTags: Set<String>
    @Binding var isPresented: Bool
    @State private var expandedCategory: String?
    @State private var tempSelection: Set<String>
    
    let flavorCategories: [(category: String, emoji: String, color: Color, flavors: [String])] = [
        ("Sweet", "🍯", .flavorSweet, ["Honey", "Caramel", "Vanilla", "Toffee", "Butterscotch", "Brown Sugar", "Maple"]),
        ("Fruity", "🍎", .flavorFruity, ["Apple", "Pear", "Citrus", "Berry", "Tropical", "Stone Fruit", "Dried Fruit"]),
        ("Spicy", "🌶️", .flavorSpicy, ["Pepper", "Cinnamon", "Nutmeg", "Clove", "Ginger", "Anise", "Cardamom"]),
        ("Woody", "🪵", .flavorWoody, ["Oak", "Cedar", "Pine", "Char", "Toasted", "Sawdust", "Pencil Shavings"]),
        ("Smoky", "💨", .flavorSmoky, ["Peat", "Ash", "Tobacco", "Leather", "Campfire", "BBQ", "Tar"]),
        ("Floral", "🌸", .flavorFloral, ["Rose", "Lavender", "Violet", "Jasmine", "Heather", "Honeysuckle", "Perfume"]),
        ("Nutty", "🥜", .flavorNutty, ["Almond", "Walnut", "Hazelnut", "Pecan", "Marzipan", "Coconut", "Cashew"]),
        ("Other", "✨", .flavorOther, ["Maritime", "Medicinal", "Herbal", "Earthy", "Mineral", "Metallic", "Solvent"])
    ]
    
    init(selectedTags: Binding<Set<String>>, isPresented: Binding<Bool>) {
        self._selectedTags = selectedTags
        self._isPresented = isPresented
        self._tempSelection = State(initialValue: selectedTags.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Selected tags preview
                if !tempSelection.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(tempSelection.sorted(), id: \.self) { tag in
                                HStack(spacing: 4) {
                                    Text(tag)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.text)
                                    
                                    Button(action: {
                                        tempSelection.remove(tag)
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption2)
                                            .foregroundColor(.textSecondary)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.surfaceSubtle)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 12)
                    .background(Color.background)
                    
                    Divider()
                }
                
                // Categories list
                List {
                    ForEach(flavorCategories, id: \.category) { item in
                        DisclosureGroup(
                            isExpanded: Binding(
                                get: { expandedCategory == item.category },
                                set: { isExpanded in
                                    withAnimation {
                                        expandedCategory = isExpanded ? item.category : nil
                                    }
                                }
                            )
                        ) {
                            // Flavor tags in category
                            ModalFlowLayout(spacing: 8) {
                                ForEach(item.flavors, id: \.self) { flavor in
                                    ModalFlavorTagButton(
                                        name: flavor,
                                        isSelected: tempSelection.contains(flavor),
                                        color: item.color
                                    ) {
                                        if tempSelection.contains(flavor) {
                                            tempSelection.remove(flavor)
                                        } else {
                                            tempSelection.insert(flavor)
                                        }
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        } label: {
                            HStack {
                                Text(item.emoji)
                                    .font(.title2)
                                
                                    Text(item.category)
                                        .font(.headline)
                                
                                Spacer()
                                
                                // Selected count badge
                                let selectedCount = item.flavors.filter { tempSelection.contains($0) }.count
                                if selectedCount > 0 {
                                    Text("\(selectedCount)")
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.onStatus)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 2)
                                        .background(item.color)
                                        .cornerRadius(10)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Select Flavors")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        selectedTags = tempSelection
                        isPresented = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Flavor Tag Button
private struct ModalFlavorTagButton: View {
    let name: String
    let isSelected: Bool
    let color: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(name)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .medium)
                .foregroundColor(isSelected ? textColorForBackground(color) : .text)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isSelected ? color : Color.surfaceSubtle)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(isSelected ? Color.clear : color.opacity(0.3), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }
    
    private func textColorForBackground(_ backgroundColor: Color) -> Color {
        // Use semantic content colors
        // Light backgrounds -> onSurface; otherwise -> onStatus
        // (Our flavor tokens skew vibrant; onStatus ensures contrast when filled.)
        return (backgroundColor == .flavorSweet || backgroundColor == .flavorFruity) ? .onSurface : .onStatus
    }
}

// MARK: - Flow Layout
private struct ModalFlowLayout: Layout {
    let spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangement(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangement(proposal: proposal, subviews: subviews)
        
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: ProposedViewSize(result.sizes[index]))
        }
    }
    
    private func arrangement(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint], sizes: [CGSize]) {
        var positions: [CGPoint] = []
        var sizes: [CGSize] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var maxWidth: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(ProposedViewSize(width: proposal.width, height: .infinity))
            
            if currentX + size.width > (proposal.width ?? .infinity), currentX > 0 {
                // Move to next line
                currentY += lineHeight + spacing
                currentX = 0
                lineHeight = 0
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            sizes.append(size)
            
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            maxWidth = max(maxWidth, currentX - spacing)
        }
        
        return (CGSize(width: maxWidth, height: currentY + lineHeight), positions, sizes)
    }
}
