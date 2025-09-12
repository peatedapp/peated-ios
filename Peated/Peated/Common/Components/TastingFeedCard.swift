import SwiftUI
import PeatedCore

struct TastingFeedCard: View {
  let tasting: TastingFeedItem
  let showBottle: Bool
  let onToast: () -> Void
  let onComment: () -> Void
  let onUserTap: () -> Void
  let onBottleTap: () -> Void
  
  @State private var showingImageViewer = false
  
  // Default initializer with bottle shown
  init(
    tasting: TastingFeedItem,
    showBottle: Bool = true,
    onToast: @escaping () -> Void,
    onComment: @escaping () -> Void,
    onUserTap: @escaping () -> Void,
    onBottleTap: @escaping () -> Void
  ) {
    self.tasting = tasting
    self.showBottle = showBottle
    self.onToast = onToast
    self.onComment = onComment
    self.onUserTap = onUserTap
    self.onBottleTap = onBottleTap
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // User header
      HStack(spacing: DesignSystem.Spacing.medium) {
        // User avatar and username (clickable for profile)
        Button(action: onUserTap) {
          HStack(spacing: DesignSystem.Spacing.medium) {
            // User avatar
            if let avatarUrl = tasting.userAvatarUrl, let url = URL(string: avatarUrl) {
              AsyncImage(url: url) { image in
                image
                  .resizable()
                  .scaledToFill()
              } placeholder: {
                Circle()
                  .fill(Color.gray.opacity(0.2))
              }
              .frame(width: DesignSystem.ImageSize.avatar.width, height: DesignSystem.ImageSize.avatar.height)
              .clipShape(Circle())
            } else {
              Circle()
                .fill(Color.gray.opacity(0.2))
                .overlay(
                  Image(systemName: "person.fill")
                    .font(.system(size: DesignSystem.FontSize.avatar))
                    .foregroundColor(.gray.opacity(0.5))
                )
                .frame(width: DesignSystem.ImageSize.avatar.width, height: DesignSystem.ImageSize.avatar.height)
            }
            
            Text(tasting.username)
              .font(.system(size: DesignSystem.FontSize.body, weight: .medium))
              .foregroundColor(.primary)
          }
        }
        .buttonStyle(PlainButtonStyle())
        
        Text("•")
          .font(.system(size: DesignSystem.FontSize.body))
          .foregroundColor(.secondary.opacity(0.5))
        
        // Time (clickable for tasting detail)
        Button(action: onBottleTap) {
          Text(tasting.timeAgo)
            .font(.system(size: DesignSystem.FontSize.body))
            .foregroundColor(.secondary)
        }
        .buttonStyle(PlainButtonStyle())
        
        Spacer()
        
        // Rating icon (right-aligned)
        if tasting.rating != 0 {
          if Int(tasting.rating) == 2 {
            // Show two thumbs up for Savor
            HStack(spacing: 2) {
              Image(systemName: "hand.thumbsup")
                .font(.system(size: DesignSystem.FontSize.body))
                .foregroundColor(.secondary)
              Image(systemName: "hand.thumbsup")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            }
          } else {
            Image(systemName: DesignSystem.ratingIcon(for: tasting.rating))
              .font(.system(size: DesignSystem.FontSize.body))
              .foregroundColor(.secondary)
          }
        }
      }
      
      // Bottle info card-within-card (only show if showBottle is true)
      if showBottle {
        HStack(spacing: DesignSystem.Spacing.medium) {
        // Bottle image or icon
        if let bottleImageUrl = tasting.bottleImageUrl, let url = URL(string: bottleImageUrl) {
          AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
              image
                .resizable()
                .aspectRatio(contentMode: .fit)
            case .failure, .empty:
              Image(systemName: "wineglass")
                .font(.system(size: DesignSystem.FontSize.headline))
                .foregroundColor(.peatedGold.opacity(DesignSystem.Opacity.strong))
            @unknown default:
              ProgressView()
                .scaleEffect(0.5)
            }
          }
          .frame(width: DesignSystem.ImageSize.bottleThumb.width, height: DesignSystem.ImageSize.bottleThumb.height)
        } else {
          Image(systemName: "wineglass")
            .font(.system(size: 18))
            .foregroundColor(.peatedGold.opacity(0.8))
            .frame(width: DesignSystem.ImageSize.bottleThumb.width, height: DesignSystem.ImageSize.bottleThumb.height)
        }
        
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xxSmall) {
          // Bottle name
          Text(tasting.bottleName)
            .font(.system(size: DesignSystem.FontSize.title, weight: .semibold))
            .foregroundColor(.primary)
            .lineLimit(1)
          
          // Distillery • Category on one line
          HStack(spacing: DesignSystem.Spacing.xSmall) {
            Text(tasting.bottleBrandName)
              .font(.system(size: DesignSystem.FontSize.body))
              .foregroundColor(.secondary)
              .lineLimit(1)
            
            if let category = tasting.bottleCategory {
              Text("•")
                .font(.system(size: DesignSystem.FontSize.body))
                .foregroundColor(.secondary.opacity(0.5))
              
              Text(category.replacingOccurrences(of: "_", with: " ").capitalized)
                .font(.system(size: DesignSystem.FontSize.body))
                .foregroundColor(.secondary)
                .lineLimit(1)
            }
          }
        }
        
        Spacer()
      }
      .padding(DesignSystem.Spacing.medium)
      .background(Color.peatedSurfaceLight.opacity(DesignSystem.Opacity.semiOpaque))
      .cornerRadius(DesignSystem.CornerRadius.medium)
      .overlay(
        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
          .stroke(Color.peatedBorder.opacity(DesignSystem.Opacity.light), lineWidth: DesignSystem.Border.thin)
      )
      .contentShape(Rectangle())
      .onTapGesture {
        onBottleTap()
      }
      }
      
      // Notes
      if let notes = tasting.notes, !notes.isEmpty {
        Text(notes)
          .font(.system(size: DesignSystem.FontSize.body))
          .foregroundColor(.primary.opacity(DesignSystem.Opacity.almostFull))
          .lineLimit(3)
          .multilineTextAlignment(.leading)
      }
      
      // Tags
      if !tasting.tags.isEmpty {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: DesignSystem.Spacing.small) {
            ForEach(tasting.tags, id: \.self) { tag in
              Text("#\(tag)")
                .tagStyle()
            }
          }
        }
      }
      
      // Tasting photo
      if let imageUrl = tasting.imageUrl, let url = URL(string: imageUrl) {
        AsyncImage(url: url) { phase in
          switch phase {
          case .success(let image):
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
              .frame(maxHeight: DesignSystem.ImageSize.photoMax)
              .clipped()
              .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
              .contentShape(Rectangle())
              .onTapGesture {
                showingImageViewer = true
              }
          case .failure, .empty:
            EmptyView()
          @unknown default:
            ProgressView()
              .frame(height: DesignSystem.ImageSize.photoMax)
          }
        }
      }
      
      // Actions bar
      HStack(spacing: DesignSystem.Spacing.xxLarge) {
        // Toast button
        Button(action: onToast) {
          HStack(spacing: DesignSystem.Spacing.small - 2) {
            Image(systemName: tasting.hasToasted ? "hands.clap.fill" : "hands.clap")
              .font(.system(size: DesignSystem.FontSize.icon))
            if tasting.toastCount > 0 {
              Text("\(tasting.toastCount)")
                .font(.system(size: DesignSystem.FontSize.body))
            }
          }
          .foregroundColor(tasting.hasToasted ? .peatedGold : .secondary)
        }
        
        // Comment button
        Button(action: onComment) {
          HStack(spacing: DesignSystem.Spacing.small - 2) {
            Image(systemName: "bubble.left")
              .font(.system(size: DesignSystem.FontSize.icon))
            if tasting.commentCount > 0 {
              Text("\(tasting.commentCount)")
                .font(.system(size: DesignSystem.FontSize.body))
            }
          }
          .foregroundColor(.secondary)
        }
        
        Spacer()
      }
      
      // Friends who also tasted
      if !tasting.friendUsernames.isEmpty {
        HStack(spacing: DesignSystem.Spacing.xSmall) {
          Image(systemName: "person.2.fill")
            .font(.system(size: DesignSystem.FontSize.caption))
            .foregroundColor(.secondary)
          
          ForEach(Array(tasting.friendUsernames.prefix(3)), id: \.self) { friend in
            Text("@\(friend)")
              .font(.system(size: DesignSystem.FontSize.small))
              .foregroundColor(.peatedGold)
          }
          
          if tasting.friendUsernames.count > 3 {
            Text("and \(tasting.friendUsernames.count - 3) more")
              .font(.system(size: DesignSystem.FontSize.small))
              .foregroundColor(.secondary)
          }
        }
      }
    }
    .padding(DesignSystem.Spacing.cardPadding)
    .background(Color(.systemBackground))
    .fullScreenCover(isPresented: $showingImageViewer) {
      if let imageUrl = tasting.imageUrl {
        ImageViewer(imageUrl: imageUrl, isPresented: $showingImageViewer)
      }
    }
  }
}

