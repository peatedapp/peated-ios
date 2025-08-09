import SwiftUI

struct WhiskyColorPicker: View {
    @Binding var selectedColor: Int?
    
    let colors: [(value: Int, name: String, hex: String)] = [
        (0, "Clear", "#ffffff"),
        (1, "White Wine", "#fff7e6"),
        (2, "Pale Straw", "#fff1d0"),
        (3, "Straw", "#ffebb8"),
        (4, "Yellow Gold", "#ffe5a0"),
        (5, "Gold", "#ffdf88"),
        (6, "Pale Gold", "#ffd970"),
        (7, "Amber", "#ffd358"),
        (8, "Deep Gold", "#ffcd40"),
        (9, "Deep Amber", "#ffc728"),
        (10, "Copper", "#ffb810"),
        (11, "Deep Copper", "#ff9f00"),
        (12, "Fine Sherry", "#e88600"),
        (13, "Bronze", "#d16d00"),
        (14, "Mahogany", "#ba5400"),
        (15, "Burnt Sienna", "#a33b00"),
        (16, "Tawny", "#8c2200"),
        (17, "Russet", "#751900"),
        (18, "Auburn", "#5e1000"),
        (19, "Burnt Umber", "#470700"),
        (20, "Black Bowmore", "#3b1d12")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with selected color name
            HStack {
                Text("Color")
                    .font(.headline)
                
                Spacer()
                
                if let selected = selectedColor,
                   let colorData = colors.first(where: { $0.value == selected }) {
                    Text(colorData.name)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else if selectedColor == -1 {
                    Text("Unsure")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Color swatches
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Unsure option
                    Button(action: {
                        selectedColor = -1
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }) {
                        Text("?")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .frame(width: 44, height: selectedColor == -1 ? 56 : 44)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.tertiarySystemBackground))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(selectedColor == -1 ? Color.accentColor : Color(.separator), 
                                                   lineWidth: selectedColor == -1 ? 2 : 1)
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    
                    // Color options
                    ForEach(colors, id: \.value) { colorData in
                        Button(action: {
                            selectedColor = colorData.value
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(hex: colorData.hex))
                                .frame(width: 44, height: selectedColor == colorData.value ? 56 : 44)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(selectedColor == colorData.value ? Color.accentColor : Color(.separator).opacity(0.3), 
                                               lineWidth: selectedColor == colorData.value ? 2 : 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}

