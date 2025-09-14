import SwiftUI
import PeatedCore

struct TastingFeedCard: View {
  let tasting: TastingFeedItem
  let showBottle: Bool
  let showUserHeader: Bool
  let onToast: () -> Void
  let onComment: () -> Void
  let onUserTap: () -> Void
  let onBottleTap: () -> Void
  
  @State private var showingImageViewer = false
  
  // Default initializer with bottle shown
  init(
    tasting: TastingFeedItem,
    showBottle: Bool = true,
    showUserHeader: Bool = true,
    onToast: @escaping () -> Void,
    onComment: @escaping () -> Void,
    onUserTap: @escaping () -> Void,
    onBottleTap: @escaping () -> Void
  ) {
    self.tasting = tasting
    self.showBottle = showBottle
    self.showUserHeader = showUserHeader
    self.onToast = onToast
    self.onComment = onComment
    self.onUserTap = onUserTap
    self.onBottleTap = onBottleTap
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // User header - refined typography (optional)
      if showUserHeader {
        HStack(alignment: .center, spacing: 10) {
          // User avatar (even smaller for elegance)
          Button(action: onUserTap) {
            if let avatarUrl = tasting.userAvatarUrl, let url = URL(string: avatarUrl) {
              AsyncImage(url: url) { image in
                image
                  .resizable()
                  .scaledToFill()
              } placeholder: {
                Circle()
                  .fill(Color.border.opacity(0.3))
              }
              .frame(width: 28, height: 28)
              .clipShape(Circle())
            } else {
              Circle()
                .fill(Color.border.opacity(0.3))
                .overlay(
                  Image(systemName: "person.fill")
                    .font(.system(size: 12))
                    .foregroundColor(Color.textSecondary)
                )
                .frame(width: 28, height: 28)
            }
          }
          .buttonStyle(PlainButtonStyle())

          // Username - lighter weight
          Text(tasting.username)
            .font(.system(size: 14, weight: .regular))
            .foregroundColor(.text)

          // Time - more subtle
          Text("· \(tasting.timeAgo)")
            .font(.system(size: 13, weight: .light))
            .foregroundColor(.textMuted)

          Spacer()

          // Rating badge - minimal
          if tasting.rating != 0 {
            Group {
              if Int(tasting.rating) == 2 {
                // Savor - elegant presentation
                Text("Savor")
                  .font(.system(size: 12, weight: .light, design: .serif))
                  .foregroundColor(.brand)
              } else if tasting.rating > 0 {
                Image(systemName: "hand.thumbsup")
                  .font(.system(size: 14, weight: .light))
                  .foregroundColor(.textMuted)
              } else {
                Image(systemName: "hand.thumbsdown")
                  .font(.system(size: 14, weight: .light))
                  .foregroundColor(.textMuted)
              }
            }
          }
        }
      }
      
      // Bottle info - inline, no background
      if showBottle {
        Button(action: onBottleTap) {
          VStack(alignment: .leading, spacing: 6) {
            // Bottle name
            Text(tasting.bottleName)
              .font(.peatedDisplaySerif)
              .foregroundColor(.text)
              .lineLimit(2)
            
            // Brand and category - sans-serif, smaller
            HStack(spacing: 6) {
              Text(tasting.bottleBrandName)
                .font(.system(size: 13, weight: .light))
                .foregroundColor(.textSecondary)
              
              if let category = tasting.bottleCategory {
                Text("·")
                  .font(.system(size: 11))
                  .foregroundColor(.textMuted)
                
                Text(category.replacingOccurrences(of: "_", with: " ").capitalized)
                  .font(.system(size: 13, weight: .light))
                  .foregroundColor(.textSecondary)
              }

              // Compact status icons inline with brand/category
              BottleStatusIcons(bottleId: tasting.bottleId)
            }
          }
        }
        .buttonStyle(PlainButtonStyle())
      }
      
      // Notes - refined typography
      if let notes = tasting.notes, !notes.isEmpty {
        Text(notes)
          .font(.system(size: 15, weight: .light))
          .foregroundColor(.text)
          .lineLimit(nil)
          .multilineTextAlignment(.leading)
          .fixedSize(horizontal: false, vertical: true)
      }
      
      // Tags - more elegant
      if !tasting.tags.isEmpty {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            ForEach(tasting.tags, id: \.self) { tag in
              Text("#\(tag)")
                .font(.system(size: 12, weight: .light))
                .foregroundColor(Color(hex: "#cf5d4e"))
            }
          }
        }
      }
      
      // Tasting photo - cleaner corners
      if let imageUrl = tasting.imageUrl, let url = URL(string: imageUrl) {
        AsyncImage(url: url) { phase in
          switch phase {
          case .success(let image):
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
              .frame(maxHeight: 300)
              .clipped()
              .clipShape(RoundedRectangle(cornerRadius: 10))
              .contentShape(Rectangle())
              .onTapGesture {
                showingImageViewer = true
              }
          case .failure, .empty:
            EmptyView()
          @unknown default:
            RoundedRectangle(cornerRadius: 10)
              .fill(Color.surfaceSubtle)
              .frame(height: 300)
              .overlay(ProgressView())
          }
        }
        .padding(.vertical, 4)
      }
      
      // Actions bar - refined and spaced
      HStack(spacing: 28) {
        // Toast button - lighter
        Button(action: onToast) {
          HStack(spacing: 5) {
            Image(systemName: tasting.hasToasted ? "hands.clap.fill" : "hands.clap")
              .font(.system(size: 17, weight: .light))
            if tasting.toastCount > 0 {
              Text("\(tasting.toastCount)")
                .font(.system(size: 13, weight: .light))
            }
          }
          .foregroundColor(tasting.hasToasted ? .brand : .textSecondary)
        }
        .buttonStyle(PlainButtonStyle())
        
        // Comment button
        Button(action: onComment) {
          HStack(spacing: 5) {
            Image(systemName: "bubble.left")
              .font(.system(size: 17, weight: .light))
            if tasting.commentCount > 0 {
              Text("\(tasting.commentCount)")
                .font(.system(size: 13, weight: .light))
            }
          }
          .foregroundColor(.textSecondary)
        }
        .buttonStyle(PlainButtonStyle())
        
        Spacer()
        
        // Share button
        Button(action: {
          // TODO: Implement share
        }) {
          Image(systemName: "square.and.arrow.up")
            .font(.system(size: 17, weight: .light))
            .foregroundColor(.textSecondary)
        }
        .buttonStyle(PlainButtonStyle())
      }
      
      // Friends who also tasted - elegant presentation
      if !tasting.friendUsernames.isEmpty {
        Text(friendsText)
          .font(.system(size: 12, weight: .light))
          .foregroundColor(.textSecondary)
          .italic()
      }
    }
    .padding(.horizontal, 20)
    .padding(.vertical, 24)
    .background(Color.background)
    .fullScreenCover(isPresented: $showingImageViewer) {
      if let imageUrl = tasting.imageUrl {
        ImageViewer(imageUrl: imageUrl, isPresented: $showingImageViewer)
      }
    }
  }
  
  private var friendsText: String {
    let friends = tasting.friendUsernames
    if friends.count == 1 {
      return "@\(friends[0]) also enjoyed this"
    } else if friends.count == 2 {
      return "@\(friends[0]) and @\(friends[1]) also enjoyed this"
    } else if friends.count > 2 {
      return "@\(friends[0]), @\(friends[1]) and \(friends.count - 2) others also enjoyed this"
    }
    return ""
  }
}
