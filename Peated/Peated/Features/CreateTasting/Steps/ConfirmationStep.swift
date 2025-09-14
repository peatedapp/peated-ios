import SwiftUI
import PeatedCore

struct ConfirmationStep: View {
    @ObservedObject var viewModel: CreateTastingViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Looking good?")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.text)
                    
                    Text("Quick check before sharing")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Tasting Preview - Clean card style
                TastingPreviewCard(viewModel: viewModel)
                    .padding(.horizontal)
                
                // Privacy Settings
                PrivacySettingsSection(
                    isPublic: $viewModel.isPublic
                )
                .padding(.horizontal)
                
                // Social Sharing (if enabled)
                if viewModel.isPublic {
                    SocialSharingSection(
                        postToFacebook: $viewModel.postToFacebook,
                        postToTwitter: $viewModel.postToTwitter
                    )
                    .padding(.horizontal)
                }
            }
            .padding(.bottom, 100) // Space for navigation buttons
        }
        .background(Color.background)
    }
}

// MARK: - Tasting Preview Card (Redesigned)
struct TastingPreviewCard: View {
    let viewModel: CreateTastingViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card content
            VStack(alignment: .leading, spacing: 12) {
                // User header (simulated)
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color.border.opacity(0.2))
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.textSecondary.opacity(0.5))
                        )
                        .frame(width: 32, height: 32)
                    
                    Text("You")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.text)
                    
                    Text("•")
                        .font(.system(size: 14))
                        .foregroundColor(.textSecondary.opacity(0.5))
                    
                    Text("now")
                        .font(.system(size: 14))
                        .foregroundColor(.textSecondary)
                    
                    Spacer()
                    
                    // Rating icon
                    if viewModel.rating != 0 {
                        if Int(viewModel.rating) == 2 {
                            // Show two thumbs up for Savor
                            HStack(spacing: 2) {
                                Image(systemName: "hand.thumbsup.fill")
                                    .font(.system(size: 14))
                        .foregroundColor(.brand)
                                Image(systemName: "hand.thumbsup.fill")
                                    .font(.system(size: 14))
                                .foregroundColor(.brand)
                            }
                        } else {
                            Image(systemName: getRatingIcon(viewModel.rating))
                                .font(.system(size: 14))
                                .foregroundColor(viewModel.rating < 0 ? .danger : .brand)
                        }
                    }
                }
                
                // Bottle info card-within-card
                if let bottle = viewModel.selectedBottle {
                    HStack(spacing: 12) {
                        // Bottle image or icon
                        BottleImage(imageUrl: bottle.imageUrl)
                            .frame(width: 28, height: 36)
                        
                        VStack(alignment: .leading, spacing: 3) {
                            // Bottle name
                            Text(bottle.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.text)
                                .lineLimit(1)
                            
                            // Brand • Category on one line
                            HStack(spacing: 4) {
                                Text(bottle.brandName)
                                    .font(.system(size: 14))
                                    .foregroundColor(.textSecondary)
                                    .lineLimit(1)
                                
                                Text("•")
                                    .font(.system(size: 14))
                                    .foregroundColor(.textSecondary.opacity(0.5))
                                
                                Text(bottle.category ?? "Whisky")
                                    .font(.system(size: 14))
                                    .foregroundColor(.textSecondary)
                                    .lineLimit(1)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(Color.surface.opacity(0.6))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.border.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // Notes
                if !viewModel.notes.isEmpty {
                    Text(viewModel.notes)
                        .font(.system(size: 14))
                        .foregroundColor(.text.opacity(0.9))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                
                // Tags
                if !viewModel.selectedTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(viewModel.selectedTags), id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.brand)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.brand.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                
                // Photo thumbnails
                if !viewModel.photos.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(viewModel.photos.enumerated()), id: \.offset) { _, photo in
                                Image(uiImage: photo)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 80)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }
                
                // Additional info (compact)
                HStack(spacing: 16) {
                    // Serving style
                    if let servingStyle = viewModel.servingStyle {
                        HStack(spacing: 4) {
                            Image(systemName: "drop")
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)
                            Text(servingStyle.displayName)
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)
                        }
                    }
                    
                    // Location
                    if let location = viewModel.selectedLocation {
                        HStack(spacing: 4) {
                            Image(systemName: "location")
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)
                            Text(location.name)
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)
                                .lineLimit(1)
                        }
                    } else if viewModel.isDrinkingAtHome {
                        HStack(spacing: 4) {
                            Image(systemName: "house")
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)
                            Text("At Home")
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.top, 4)
            }
            .padding()
            .background(Color.surface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.border.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

// MARK: - Privacy Settings Section (Updated)
struct PrivacySettingsSection: View {
    @Binding var isPublic: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Privacy")
                .font(.headline)
            
            HStack(spacing: 12) {
                PrivacyOption(
                    title: "Public",
                    subtitle: "Share with everyone",
                    icon: "globe",
                    isSelected: isPublic,
                    onTap: { isPublic = true }
                )
                
                PrivacyOption(
                    title: "Private",
                    subtitle: "Just for you",
                    icon: "lock.fill",
                    isSelected: !isPublic,
                    onTap: { isPublic = false }
                )
            }
        }
    }
}

// MARK: - Privacy Option (Simplified)
struct PrivacyOption: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .symbolRenderingMode(isSelected ? .multicolor : .monochrome)
                    .foregroundColor(isSelected ? .brand : .secondary)
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(.textSecondary)
                    .opacity(isSelected ? 1 : 0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.brand.opacity(0.1) : Color.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.brand : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Social Sharing Section (Cleaner)
struct SocialSharingSection: View {
    @Binding var postToFacebook: Bool
    @Binding var postToTwitter: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Share to")
                .font(.headline)
            
            VStack(spacing: 8) {
                SocialToggle(
                    platform: "Facebook",
                    icon: "f.circle.fill",
                    isEnabled: $postToFacebook
                )
                
                SocialToggle(
                    platform: "X (Twitter)",
                    icon: "x.circle.fill",
                    isEnabled: $postToTwitter
                )
            }
        }
    }
}

// MARK: - Social Toggle (Simplified)
struct SocialToggle: View {
    let platform: String
    let icon: String
    @Binding var isEnabled: Bool
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.textSecondary)
                .frame(width: 24)
            
            Text(platform)
                .font(.system(size: 14))
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
                .toggleStyle(SwitchToggleStyle(tint: .brand))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.surface)
        .cornerRadius(10)
    }
}

// MARK: - Helper Functions
private func getRatingIcon(_ rating: Double) -> String {
    switch Int(rating) {
    case -1:
        return "hand.thumbsdown.fill"
    case 1:
        return "hand.thumbsup.fill"
    case 2:
        return "hand.thumbsup.fill" // Will show two
    default:
        return "minus.circle"
    }
}
