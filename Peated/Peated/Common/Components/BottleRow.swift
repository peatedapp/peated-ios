import SwiftUI
import PeatedCore

struct BottleRow: View {
  let bottle: Bottle
  let isSelected: Bool
  let subtitle: BottleRowSubtitle?
  let onTap: () -> Void
  
  enum BottleRowSubtitle {
    case rating
    case lastTasting(TastingFeedItem)
    
    @ViewBuilder
    var view: some View {
      switch self {
      case .rating:
        EmptyView() // Handled in main view
      case .lastTasting(let tasting):
        HStack(spacing: DesignSystem.Spacing.xSmall) {
          // Show rating icon based on value
          if DesignSystem.isDoubleThumbsUp(tasting.rating) {
            // Two thumbs up for Savor
            HStack(spacing: 2) {
              Image(systemName: "hand.thumbsup")
                .font(.system(size: DesignSystem.FontSize.tiny))
                .foregroundColor(.secondary)
              Image(systemName: "hand.thumbsup")
                .font(.system(size: DesignSystem.FontSize.tiny))
                .foregroundColor(.secondary)
            }
          } else if Int(tasting.rating) == 1 {
            Image(systemName: "hand.thumbsup")
              .font(.system(size: DesignSystem.FontSize.tiny))
              .foregroundColor(.secondary)
          } else if Int(tasting.rating) == -1 {
            Image(systemName: "hand.thumbsdown")
              .font(.system(size: DesignSystem.FontSize.tiny))
              .foregroundColor(.secondary)
          }
          
          Text("Last: \(tasting.timeAgo)")
            .font(.system(size: DesignSystem.FontSize.small))
            .foregroundColor(.secondary)
        }
      }
    }
  }
  
  init(
    bottle: Bottle,
    isSelected: Bool = false,
    subtitle: BottleRowSubtitle? = nil,
    onTap: @escaping () -> Void
  ) {
    self.bottle = bottle
    self.isSelected = isSelected
    self.subtitle = subtitle
    self.onTap = onTap
  }
  
  var body: some View {
    Button(action: onTap) {
      HStack(spacing: DesignSystem.Spacing.medium) {
        // Bottle image
        BottleImage(imageUrl: bottle.imageUrl)
          .frame(
            width: DesignSystem.ImageSize.bottleThumb.width,
            height: DesignSystem.ImageSize.bottleThumb.height
          )
        
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxSmall) {
          // Bottle name with proper truncation
          Text(bottle.fullName)
            .font(.system(size: DesignSystem.FontSize.title, weight: .semibold))
            .foregroundColor(.primary)
            .lineLimit(1)
            .truncationMode(.tail)
          
          // Brand • Category on one line
          HStack(spacing: DesignSystem.Spacing.xSmall) {
            Text(bottle.brandName)
              .font(.system(size: DesignSystem.FontSize.body))
              .foregroundColor(.secondary)
              .lineLimit(1)
              .truncationMode(.tail)
              .layoutPriority(1)
            
            if let category = bottle.category {
              Text("•")
                .font(.system(size: DesignSystem.FontSize.body))
                .foregroundColor(.secondary.opacity(0.5))
              
              Text(category.replacingOccurrences(of: "_", with: " ").capitalized)
                .font(.system(size: DesignSystem.FontSize.body))
                .foregroundColor(.secondary)
                .lineLimit(1)
            }
          }
          
          // Subtitle content
          if let subtitle = subtitle {
            if case .rating = subtitle, bottle.totalRatings > 0 {
              // Rating stars
              HStack(spacing: DesignSystem.Spacing.xSmall) {
                ForEach(1...5, id: \.self) { star in
                  Image(systemName: star <= Int(bottle.avgRating.rounded()) ? "star.fill" : "star")
                    .font(.system(size: DesignSystem.FontSize.tiny))
                    .foregroundColor(.yellow)
                }
                Text(String(format: "%.1f", bottle.avgRating))
                  .font(.system(size: DesignSystem.FontSize.small))
                  .foregroundColor(.secondary)
                Text("(\(bottle.totalRatings))")
                  .font(.system(size: DesignSystem.FontSize.small))
                  .foregroundColor(.secondary.opacity(DesignSystem.Opacity.dimmed))
              }
            } else {
              subtitle.view
            }
          }
        }
        
        Spacer(minLength: DesignSystem.Spacing.small)
        
        if isSelected {
          Image(systemName: "checkmark.circle.fill")
            .foregroundColor(.peatedGold)
            .font(.system(size: 20))
        }
      }
      .bottleCardStyle(isSelected: isSelected)
    }
    .buttonStyle(.plain)
  }
}

// MARK: - Bottle Image Component
struct BottleImage: View {
  let imageUrl: String?
  
  var body: some View {
    if let imageUrl = imageUrl, let url = URL(string: imageUrl) {
      AsyncImage(url: url) { phase in
        switch phase {
        case .success(let image):
          image
            .resizable()
            .aspectRatio(contentMode: .fit)
        case .failure, .empty:
          defaultBottleIcon
        @unknown default:
          ProgressView()
            .scaleEffect(0.5)
        }
      }
    } else {
      defaultBottleIcon
    }
  }
  
  private var defaultBottleIcon: some View {
    Image(systemName: "wineglass")
      .font(.system(size: 18))
      .foregroundColor(.peatedGold.opacity(DesignSystem.Opacity.strong))
  }
}