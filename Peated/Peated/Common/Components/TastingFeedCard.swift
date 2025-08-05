import SwiftUI
import PeatedCore

struct TastingFeedCard: View {
  let tasting: TastingFeedItem
  let onToast: () -> Void
  let onComment: () -> Void
  let onUserTap: () -> Void
  let onBottleTap: () -> Void
  
  @State private var showingImageViewer = false
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // User header
      HStack(spacing: 10) {
        // User avatar and username (clickable for profile)
        Button(action: onUserTap) {
          HStack(spacing: 10) {
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
              .frame(width: 32, height: 32)
              .clipShape(Circle())
            } else {
              Circle()
                .fill(Color.gray.opacity(0.2))
                .overlay(
                  Image(systemName: "person.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.gray.opacity(0.5))
                )
                .frame(width: 32, height: 32)
            }
            
            Text(tasting.username)
              .font(.system(size: 14, weight: .medium))
              .foregroundColor(.primary)
          }
        }
        .buttonStyle(PlainButtonStyle())
        
        Text("•")
          .font(.system(size: 14))
          .foregroundColor(.secondary.opacity(0.5))
        
        // Time (clickable for tasting detail)
        Button(action: onBottleTap) {
          Text(tasting.timeAgo)
            .font(.system(size: 14))
            .foregroundColor(.secondary)
        }
        .buttonStyle(PlainButtonStyle())
        
        Spacer()
      }
      
      // Bottle info card-within-card
      HStack(spacing: 12) {
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
                .font(.system(size: 18))
                .foregroundColor(.peatedGold.opacity(0.8))
            @unknown default:
              ProgressView()
                .scaleEffect(0.5)
            }
          }
          .frame(width: 28, height: 36)
        } else {
          Image(systemName: "wineglass")
            .font(.system(size: 18))
            .foregroundColor(.peatedGold.opacity(0.8))
            .frame(width: 28, height: 36)
        }
        
        VStack(alignment: .leading, spacing: 3) {
          // Bottle name
          Text(tasting.bottleName)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.primary)
            .lineLimit(1)
          
          // Distillery • Category on one line
          HStack(spacing: 4) {
            Text(tasting.bottleBrandName)
              .font(.system(size: 14))
              .foregroundColor(.secondary)
              .lineLimit(1)
            
            if let category = tasting.bottleCategory {
              Text("•")
                .font(.system(size: 14))
                .foregroundColor(.secondary.opacity(0.5))
              
              Text(category.capitalized)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .lineLimit(1)
            }
          }
        }
        
        Spacer()
      }
      .padding(12)
      .background(Color.peatedSurfaceLight)
      .cornerRadius(10)
      .overlay(
        RoundedRectangle(cornerRadius: 10)
          .stroke(Color.peatedBorder.opacity(0.5), lineWidth: 1)
      )
      .contentShape(Rectangle())
      .onTapGesture {
        onBottleTap()
      }
      
      // Notes
      if let notes = tasting.notes, !notes.isEmpty {
        Text(notes)
          .font(.system(size: 14))
          .foregroundColor(.primary.opacity(0.9))
          .lineLimit(3)
          .multilineTextAlignment(.leading)
      }
      
      // Tags
      if !tasting.tags.isEmpty {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            ForEach(tasting.tags, id: \.self) { tag in
              Text("#\(tag)")
                .font(.system(size: 12))
                .foregroundColor(.peatedGold)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.peatedGold.opacity(0.1))
                .clipShape(Capsule())
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
              .frame(maxHeight: 200)
              .clipped()
              .clipShape(RoundedRectangle(cornerRadius: 12))
              .contentShape(Rectangle())
              .onTapGesture {
                showingImageViewer = true
              }
          case .failure, .empty:
            EmptyView()
          @unknown default:
            ProgressView()
              .frame(height: 200)
          }
        }
      }
      
      // Actions bar
      HStack(spacing: 24) {
        // Toast button
        Button(action: onToast) {
          HStack(spacing: 6) {
            Image(systemName: tasting.hasToasted ? "hands.clap.fill" : "hands.clap")
              .font(.system(size: 16))
            if tasting.toastCount > 0 {
              Text("\(tasting.toastCount)")
                .font(.system(size: 14))
            }
          }
          .foregroundColor(tasting.hasToasted ? .peatedGold : .secondary)
        }
        
        // Comment button
        Button(action: onComment) {
          HStack(spacing: 6) {
            Image(systemName: "bubble.left")
              .font(.system(size: 16))
            if tasting.commentCount > 0 {
              Text("\(tasting.commentCount)")
                .font(.system(size: 14))
            }
          }
          .foregroundColor(.secondary)
        }
        
        Spacer()
      }
      
      // Friends who also tasted
      if !tasting.friendUsernames.isEmpty {
        HStack(spacing: 4) {
          Image(systemName: "person.2.fill")
            .font(.system(size: 11))
            .foregroundColor(.secondary)
          
          ForEach(Array(tasting.friendUsernames.prefix(3)), id: \.self) { friend in
            Text("@\(friend)")
              .font(.system(size: 12))
              .foregroundColor(.peatedGold)
          }
          
          if tasting.friendUsernames.count > 3 {
            Text("and \(tasting.friendUsernames.count - 3) more")
              .font(.system(size: 12))
              .foregroundColor(.secondary)
          }
        }
      }
    }
    .padding(16)
    .background(Color(.systemBackground))
    .fullScreenCover(isPresented: $showingImageViewer) {
      if let imageUrl = tasting.imageUrl {
        ImageViewer(imageUrl: imageUrl, isPresented: $showingImageViewer)
      }
    }
  }
}