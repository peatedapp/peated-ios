import SwiftUI
import PeatedCore

struct TastingCard: View {
  let tasting: TastingFeedItem
  let onToast: () -> Void
  let onComment: () -> Void
  let onUserTap: () -> Void
  let onBottleTap: () -> Void
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // Main content
      HStack(alignment: .top, spacing: 12) {
        // Bottle image
        if let imageUrl = tasting.bottleImageUrl, let url = URL(string: imageUrl) {
          AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
              image
                .resizable()
                .aspectRatio(contentMode: .fit)
            case .failure(_), .empty:
              Image(systemName: "wineglass")
                .font(.system(size: 20))
                .foregroundColor(.gray.opacity(0.5))
            @unknown default:
              ProgressView()
            }
          }
          .frame(width: 48, height: 64)
          .background(Color.gray.opacity(0.1))
          .clipShape(RoundedRectangle(cornerRadius: 4))
          .onTapGesture {
            onBottleTap()
          }
        } else {
          RoundedRectangle(cornerRadius: 4)
            .fill(Color.gray.opacity(0.1))
            .frame(width: 48, height: 64)
            .overlay(
              Image(systemName: "wineglass")
                .font(.system(size: 20))
                .foregroundColor(.gray.opacity(0.5))
            )
            .onTapGesture {
              onBottleTap()
            }
        }
        
        VStack(alignment: .leading, spacing: 4) {
          // Bottle name
          Text(tasting.bottleName)
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(.primary)
            .lineLimit(1)
            .onTapGesture {
              onBottleTap()
            }
          
          // Brand and category
          HStack(spacing: 4) {
            Text(tasting.bottleBrandName)
              .font(.system(size: 13))
              .foregroundColor(.secondary)
            
            if let category = tasting.bottleCategory {
              Text("•")
                .font(.system(size: 13))
                .foregroundColor(.secondary.opacity(0.5))
              
              Text(category.capitalized)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            }
          }
          .lineLimit(1)
          
          // Serving style
          if let servingStyle = tasting.servingStyle {
            HStack {
              Text(servingStyle.capitalized)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.gray.opacity(0.1))
                .clipShape(Capsule())
              Spacer()
            }
          }
          
          // Notes
          if let notes = tasting.notes, !notes.isEmpty {
            Text(notes)
              .font(.system(size: 14))
              .foregroundColor(.primary.opacity(0.9))
              .lineLimit(2)
              .multilineTextAlignment(.leading)
              .padding(.top, 4)
          }
          
          // Tags
          if !tasting.tags.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
              HStack(spacing: 6) {
                ForEach(tasting.tags, id: \.self) { tag in
                  Text("#\(tag)")
                    .font(.system(size: 12))
                    .foregroundColor(.peatedGold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.peatedGold.opacity(0.1))
                    .clipShape(Capsule())
                }
              }
            }
            .padding(.top, 6)
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
                  .clipShape(RoundedRectangle(cornerRadius: 8))
              case .failure(_), .empty:
                EmptyView()
              @unknown default:
                ProgressView()
                  .frame(height: 200)
              }
            }
            .padding(.top, 8)
          }
          
          // User info and actions
          HStack(spacing: 12) {
            // User
            HStack(spacing: 6) {
              if let avatarUrl = tasting.userAvatarUrl, let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { image in
                  image
                    .resizable()
                    .scaledToFill()
                } placeholder: {
                  Circle()
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                      Image(systemName: "person.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.gray.opacity(0.5))
                    )
                }
                .frame(width: 20, height: 20)
                .clipShape(Circle())
              } else {
                Circle()
                  .fill(Color.gray.opacity(0.2))
                  .overlay(
                    Image(systemName: "person.fill")
                      .font(.system(size: 10))
                      .foregroundColor(.gray.opacity(0.5))
                  )
                  .frame(width: 20, height: 20)
              }
              
              Text(tasting.username)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
              
              Text("•")
                .font(.system(size: 13))
                .foregroundColor(.secondary.opacity(0.5))
              
              Text(tasting.timeAgo)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
            }
            .onTapGesture {
              onUserTap()
            }
            
            // Friends who also tasted
            if !tasting.friendUsernames.isEmpty {
              HStack(spacing: 4) {
                Text("with")
                  .font(.system(size: 13))
                  .foregroundColor(.secondary)
                
                ForEach(Array(tasting.friendUsernames.prefix(2)), id: \.self) { friend in
                  Text("@\(friend)")
                    .font(.system(size: 13))
                    .foregroundColor(.peatedGold)
                }
                
                if tasting.friendUsernames.count > 2 {
                  Text("+\(tasting.friendUsernames.count - 2)")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                }
              }
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 16) {
              Button(action: onToast) {
                HStack(spacing: 4) {
                  Image(systemName: tasting.hasToasted ? "hands.clap.fill" : "hands.clap")
                    .font(.system(size: 14))
                  Text("\(tasting.toastCount)")
                    .font(.system(size: 13))
                }
                .foregroundColor(tasting.hasToasted ? .peatedGold : .secondary)
              }
              .buttonStyle(.plain)
              
              Button(action: onComment) {
                HStack(spacing: 4) {
                  Image(systemName: "bubble.left")
                    .font(.system(size: 14))
                  Text("\(tasting.commentCount)")
                    .font(.system(size: 13))
                }
                .foregroundColor(.secondary)
              }
              .buttonStyle(.plain)
            }
          }
          .padding(.top, 8)
        }
      }
      .padding(16)
    }
    .background(Color(.systemBackground))
  }
}