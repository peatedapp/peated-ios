import SwiftUI
import PeatedCore

struct ConfirmationStep: View {
    @ObservedObject var viewModel: CreateTastingViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Review your tasting")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Double-check everything looks good before sharing")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top)
                
                VStack(spacing: 20) {
                    // Tasting Preview
                    TastingPreviewCard(viewModel: viewModel)
                    
                    // Privacy Settings
                    PrivacySettingsSection(
                        isPublic: $viewModel.isPublic
                    )
                    
                    // Social Sharing (if enabled)
                    if viewModel.isPublic {
                        SocialSharingSection(
                            postToFacebook: $viewModel.postToFacebook,
                            postToTwitter: $viewModel.postToTwitter
                        )
                    }
                    
                    // Final Notes
                    ConfirmationNotesSection()
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 100) // Space for navigation buttons
        }
    }
}

// MARK: - Tasting Preview Card
struct TastingPreviewCard: View {
    let viewModel: CreateTastingViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Tasting")
                .font(.headline)
            
            VStack(spacing: 16) {
                // Bottle Info
                if let bottle = viewModel.selectedBottle {
                    HStack(spacing: 12) {
                        AsyncImage(url: URL(string: bottle.imageUrl ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        } placeholder: {
                            Image(systemName: "wineglass")
                                .font(.title)
                                .foregroundColor(.secondary)
                                .frame(width: 50, height: 70)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        .frame(width: 50, height: 70)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(bottle.name)
                                .font(.body)
                                .fontWeight(.medium)
                                .lineLimit(2)
                            
                            Text(bottle.brandName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                
                Divider()
                
                // Rating
                VStack(alignment: .leading, spacing: 8) {
                    Text("Rating")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Text(getRatingDisplay(viewModel.rating))
                            .font(.body)
                            .fontWeight(.medium)
                    }
                }
                
                // Notes
                if !viewModel.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(viewModel.notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                    }
                }
                
                // Serving Style
                if let servingStyle = viewModel.servingStyle {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Serving Style")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(servingStyle.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Tags
                if !viewModel.selectedTags.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Flavor Tags")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        FlowLayout(spacing: 4) {
                            ForEach(Array(viewModel.selectedTags), id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.accentColor.opacity(0.2))
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
                
                // Location
                if let location = viewModel.selectedLocation {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(location.name)
                                .font(.caption)
                                .foregroundColor(.primary)
                            
                            if let address = location.address {
                                Text(address)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                } else if viewModel.isDrinkingAtHome {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("At Home")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Photos
                if !viewModel.photos.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Photos")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(Array(viewModel.photos.enumerated()), id: \.offset) { _, photo in
                                    Image(uiImage: photo)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 60, height: 60)
                                        .clipped()
                                        .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal, 1)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
}

// MARK: - Privacy Settings Section
struct PrivacySettingsSection: View {
    @Binding var isPublic: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Privacy")
                .font(.headline)
            
            VStack(spacing: 12) {
                PrivacyOption(
                    title: "Public",
                    subtitle: "Everyone can see this tasting",
                    icon: "globe",
                    isSelected: isPublic,
                    onTap: { isPublic = true }
                )
                
                PrivacyOption(
                    title: "Private",
                    subtitle: "Only you can see this tasting",
                    icon: "lock",
                    isSelected: !isPublic,
                    onTap: { isPublic = false }
                )
            }
        }
    }
}

// MARK: - Privacy Option
struct PrivacyOption: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : .accentColor)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.white)
                }
            }
            .padding()
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
    }
}

// MARK: - Social Sharing Section
struct SocialSharingSection: View {
    @Binding var postToFacebook: Bool
    @Binding var postToTwitter: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Share To")
                .font(.headline)
            
            VStack(spacing: 12) {
                SocialToggle(
                    platform: "Facebook",
                    icon: "f.square",
                    isEnabled: $postToFacebook
                )
                
                SocialToggle(
                    platform: "Twitter",
                    icon: "x.square", // or use a custom Twitter icon
                    isEnabled: $postToTwitter
                )
            }
        }
    }
}

// MARK: - Social Toggle
struct SocialToggle: View {
    let platform: String
    let icon: String
    @Binding var isEnabled: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            
            Text("Post to \(platform)")
                .font(.body)
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
                .toggleStyle(SwitchToggleStyle(tint: .accentColor))
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Confirmation Notes Section
struct ConfirmationNotesSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle")
                    .foregroundColor(.accentColor)
                
                Text("Almost there!")
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("• Your tasting will be saved to your profile")
                Text("• You can edit or delete it later if needed")
                Text("• Friends will be notified if this is public")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.accentColor.opacity(0.1))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Flow Layout for Tags
struct FlowLayout: Layout {
    let spacing: CGFloat
    
    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrangeSubviews(proposal: proposal, subviews: subviews)
        let totalHeight = rows.reduce(0) { result, row in
            result + row.maxHeight + (result > 0 ? spacing : 0)
        }
        return CGSize(width: proposal.width ?? 0, height: totalHeight)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrangeSubviews(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        
        for row in rows {
            var x = bounds.minX
            for subview in row.subviews {
                let size = subview.sizeThatFits(.unspecified)
                subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.maxHeight + spacing
        }
    }
    
    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var currentRow = Row()
        var currentRowWidth: CGFloat = 0
        let maxWidth = proposal.width ?? .infinity
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentRowWidth + size.width > maxWidth && !currentRow.subviews.isEmpty {
                rows.append(currentRow)
                currentRow = Row()
                currentRowWidth = 0
            }
            
            currentRow.subviews.append(subview)
            currentRow.maxHeight = max(currentRow.maxHeight, size.height)
            currentRowWidth += size.width + spacing
        }
        
        if !currentRow.subviews.isEmpty {
            rows.append(currentRow)
        }
        
        return rows
    }
    
    private struct Row {
        var subviews: [LayoutSubview] = []
        var maxHeight: CGFloat = 0
    }
}

// MARK: - Helper Functions
private func getRatingDisplay(_ rating: Double) -> String {
    switch Int(rating) {
    case -1:
        return "👎 Pass"
    case 1:
        return "👍 Sip"
    case 2:
        return "👍👍 Savor"
    default:
        return "No rating"
    }
}