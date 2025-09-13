import SwiftUI
import PeatedCore

struct UnifiedTastingCard: View {
  let tasting: TastingFeedItem
  let onToast: () -> Void
  let onComment: () -> Void
  let onUserTap: () -> Void
  let onBottleTap: () -> Void
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Header with bottle info and image (like detail view)
      HStack(alignment: .top, spacing: 12) {
        // Bottle image
        if let imageUrl = tasting.bottleImageUrl, let url = URL(string: imageUrl) {
          AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
              image
                .resizable()
                .aspectRatio(contentMode: .fit)
            case .failure, .empty:
              Image(systemName: "wineglass")
                .font(.system(size: 24))
                .foregroundColor(.textMuted)
            @unknown default:
              ProgressView()
            }
          }
          .frame(width: 48, height: 48)
          .background(Color.surface)
          .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
          // Placeholder
          RoundedRectangle(cornerRadius: 8)
            .fill(Color.surface)
            .frame(width: 48, height: 48)
            .overlay(
              Image(systemName: "wineglass")
                .font(.system(size: 24))
                .foregroundColor(.textMuted)
            )
        }
        
        VStack(alignment: .leading, spacing: 4) {
          Text(tasting.bottleName)
            .font(.peatedDisplaySerif)
            .foregroundColor(.text)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
            .onTapGesture {
              onBottleTap()
            }
          
          HStack(spacing: 4) {
            Text(tasting.bottleBrandName)
              .font(.peatedSubheadline)
              .foregroundColor(.textSecondary)
            
            if let category = tasting.bottleCategory {
              Text("•")
                .font(.peatedSubheadline)
                .foregroundColor(.textMuted)
              
              Text(category.capitalized)
                .font(.peatedSubheadline)
                .foregroundColor(.textSecondary)
            }
          }
          .lineLimit(1)
        }
        
        Spacer()
        
        // Rating icon (right-aligned)
        if tasting.rating != 0 {
          if Int(tasting.rating) == 2 {
            // Show two thumbs up for Savor
            HStack(spacing: 2) {
              Image(systemName: "hand.thumbsup")
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
              Image(systemName: "hand.thumbsup")
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
            }
          } else {
            Image(systemName: getRatingIcon(tasting.rating))
              .font(.system(size: 14))
              .foregroundColor(.textSecondary)
          }
        }
      }
      
      // Notes (truncated for feed)
      if let notes = tasting.notes, !notes.isEmpty {
        Text(notes)
          .font(.peatedBody)
          .foregroundColor(.text)
          .lineLimit(2)
          .multilineTextAlignment(.leading)
      }
      
      // Tags
      if !tasting.tags.isEmpty {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            ForEach(tasting.tags, id: \.self) { tag in
              Text("#\(tag)")
                .font(.peatedFootnote)
                .foregroundColor(.brand)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.brand.opacity(0.1))
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
          case .failure, .empty:
            EmptyView()
          @unknown default:
            ProgressView()
              .frame(height: 200)
          }
        }
        .onTapGesture {
          onComment() // Navigate to detail
        }
      }
      
      // User info and actions (like detail view)
      HStack {
        // User avatar and info
        HStack(spacing: 8) {
          if let avatarUrl = tasting.userAvatarUrl, let url = URL(string: avatarUrl) {
            AsyncImage(url: url) { image in
              image
                .resizable()
                .scaledToFill()
            } placeholder: {
              Circle()
                .fill(Color.surface)
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())
          } else {
            Circle()
              .fill(Color.surface)
              .overlay(
                Image(systemName: "person.fill")
                  .font(.system(size: 16))
                  .foregroundColor(.textMuted)
              )
              .frame(width: 32, height: 32)
          }
          
          VStack(alignment: .leading, spacing: 2) {
            Text(tasting.username)
              .font(.peatedSubheadline)
              .fontWeight(.medium)
              .foregroundColor(.text)
            
            Text(tasting.timeAgo)
              .font(.peatedCaption)
              .foregroundColor(.textSecondary)
          }
        }
        .contentShape(Rectangle())
        .onTapGesture {
          onUserTap()
        }
        
        Spacer()
        
        // Actions
        HStack(spacing: 20) {
          // Toast button
          Button(action: onToast) {
            HStack(spacing: 4) {
              Image(systemName: tasting.hasToasted ? "hands.clap.fill" : "hands.clap")
                .font(.system(size: 16))
              Text("\(tasting.toastCount)")
                .font(.peatedSubheadline)
            }
            .foregroundColor(tasting.hasToasted ? .brand : .textSecondary)
          }
          
          // Comment button
          Button(action: onComment) {
            HStack(spacing: 4) {
              Image(systemName: "bubble.left")
                .font(.system(size: 16))
              Text("\(tasting.commentCount)")
                .font(.peatedSubheadline)
            }
            .foregroundColor(.textSecondary)
          }
        }
      }
      
      // Friends who also tasted
      if !tasting.friendUsernames.isEmpty {
        HStack(spacing: 4) {
          Image(systemName: "person.2.fill")
            .font(.system(size: 11))
            .foregroundColor(.textSecondary)
          
          ForEach(Array(tasting.friendUsernames.prefix(3)), id: \.self) { friend in
            Text("@\(friend)")
              .font(.peatedCaption)
              .foregroundColor(.brand)
          }
          
          if tasting.friendUsernames.count > 3 {
            Text("and \(tasting.friendUsernames.count - 3) more")
              .font(.peatedCaption)
              .foregroundColor(.textSecondary)
          }
        }
      }
    }
    .padding()
    .background(Color.surface)
    .cornerRadius(12)
  }
}

// Wrapper for list usage without the rounded background
struct UnifiedTastingListItem: View {
  let tasting: TastingFeedItem
  let onToast: () -> Void
  let onComment: () -> Void
  let onUserTap: () -> Void
  let onBottleTap: () -> Void
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Header with bottle info and image (like detail view)
      HStack(alignment: .top, spacing: 12) {
        // Bottle image
        if let imageUrl = tasting.bottleImageUrl, let url = URL(string: imageUrl) {
          AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
              image
                .resizable()
                .aspectRatio(contentMode: .fit)
            case .failure, .empty:
              Image(systemName: "wineglass")
                .font(.system(size: 24))
                .foregroundColor(.textMuted)
            @unknown default:
              ProgressView()
            }
          }
          .frame(width: 48, height: 48)
          .background(Color.surface)
          .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
          // Placeholder
          RoundedRectangle(cornerRadius: 8)
            .fill(Color.surface)
            .frame(width: 48, height: 48)
            .overlay(
              Image(systemName: "wineglass")
                .font(.system(size: 24))
                .foregroundColor(.textMuted)
            )
        }
        
        VStack(alignment: .leading, spacing: 4) {
          Text(tasting.bottleName)
            .font(.peatedDisplaySerif)
            .foregroundColor(.text)
            .lineLimit(2)
            .fixedSize(horizontal: false, vertical: true)
            .onTapGesture {
              onBottleTap()
            }
          
          HStack(spacing: 4) {
            Text(tasting.bottleBrandName)
              .font(.peatedSubheadline)
              .foregroundColor(.textSecondary)
            
            if let category = tasting.bottleCategory {
              Text("•")
                .font(.peatedSubheadline)
                .foregroundColor(.textMuted)
              
              Text(category.capitalized)
                .font(.peatedSubheadline)
                .foregroundColor(.textSecondary)
            }
          }
          .lineLimit(1)
        }
        
        Spacer()
        
        // Rating icon (right-aligned)
        if tasting.rating != 0 {
          if Int(tasting.rating) == 2 {
            // Show two thumbs up for Savor
            HStack(spacing: 2) {
              Image(systemName: "hand.thumbsup")
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
              Image(systemName: "hand.thumbsup")
                .font(.system(size: 14))
                .foregroundColor(.textSecondary)
            }
          } else {
            Image(systemName: getRatingIcon(tasting.rating))
              .font(.system(size: 14))
              .foregroundColor(.secondary)
          }
        }
      }
      
      // Notes (truncated for feed)
      if let notes = tasting.notes, !notes.isEmpty {
        Text(notes)
          .font(.peatedBody)
          .foregroundColor(.text)
          .lineLimit(2)
          .multilineTextAlignment(.leading)
      }
      
      // Tags
      if !tasting.tags.isEmpty {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            ForEach(tasting.tags, id: \.self) { tag in
              Text("#\(tag)")
                .font(.peatedCaption)
                .foregroundColor(.brand)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.brand.opacity(0.1))
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
          case .failure, .empty:
            EmptyView()
          @unknown default:
            ProgressView()
              .frame(height: 200)
          }
        }
        .onTapGesture {
          onComment() // Navigate to detail
        }
      }
      
      // User info and actions (like detail view)
      HStack {
        // User avatar and info
        HStack(spacing: 8) {
          if let avatarUrl = tasting.userAvatarUrl, let url = URL(string: avatarUrl) {
            AsyncImage(url: url) { image in
              image
                .resizable()
                .scaledToFill()
            } placeholder: {
              Circle()
                .fill(Color.surface)
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())
          } else {
            Circle()
              .fill(Color.surface)
              .overlay(
                Image(systemName: "person.fill")
                  .font(.system(size: 16))
                  .foregroundColor(.textMuted)
              )
              .frame(width: 32, height: 32)
          }
          
          VStack(alignment: .leading, spacing: 2) {
            Text(tasting.username)
              .font(.peatedSubheadline)
              .fontWeight(.medium)
              .foregroundColor(.text)
            
            Text(tasting.timeAgo)
              .font(.peatedCaption)
              .foregroundColor(.textSecondary)
          }
        }
        .contentShape(Rectangle())
        .onTapGesture {
          onUserTap()
        }
        
        Spacer()
        
        // Actions
        HStack(spacing: 20) {
          // Toast button
          Button(action: onToast) {
            HStack(spacing: 4) {
              Image(systemName: tasting.hasToasted ? "hands.clap.fill" : "hands.clap")
                .font(.system(size: 16))
              Text("\(tasting.toastCount)")
                .font(.peatedSubheadline)
            }
            .foregroundColor(tasting.hasToasted ? .brand : .textSecondary)
          }
          
          // Comment button
          Button(action: onComment) {
            HStack(spacing: 4) {
              Image(systemName: "bubble.left")
                .font(.system(size: 16))
              Text("\(tasting.commentCount)")
                .font(.peatedSubheadline)
            }
            .foregroundColor(.textSecondary)
          }
        }
      }
      
      // Friends who also tasted
      if !tasting.friendUsernames.isEmpty {
        HStack(spacing: 4) {
          Image(systemName: "person.2.fill")
            .font(.system(size: 11))
            .foregroundColor(.textSecondary)
          
          ForEach(Array(tasting.friendUsernames.prefix(3)), id: \.self) { friend in
            Text("@\(friend)")
              .font(.peatedCaption)
              .foregroundColor(.brand)
          }
          
          if tasting.friendUsernames.count > 3 {
            Text("and \(tasting.friendUsernames.count - 3) more")
              .font(.peatedCaption)
              .foregroundColor(.textSecondary)
          }
        }
      }
    }
    .padding()
    .background(Color.background)
  }
}

// MARK: - Helper Functions
private func getRatingIcon(_ rating: Double) -> String {
  switch Int(rating) {
  case -1:
    return "hand.thumbsdown"
  case 1:
    return "hand.thumbsup"
  default:
    return "star"
  }
}
