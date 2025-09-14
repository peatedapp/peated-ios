import SwiftUI

struct AvatarImage: View {
  let urlString: String?
  let size: CGFloat

  init(urlString: String?, size: CGFloat) {
    self.urlString = urlString
    self.size = size
  }

  private var cornerRadius: CGFloat { DesignSystem.CornerRadius.large }

  var body: some View {
    Group {
      if let urlString, let url = URL(string: urlString) {
        CachedAsyncImage(url: url) { image in
          image
            .resizable()
            .scaledToFill()
        } placeholder: {
          RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.border.opacity(0.3))
            .overlay(
              Image(systemName: "person.fill")
                .font(.system(size: size * 0.45))
                .foregroundColor(.textMuted)
            )
        }
        .task(id: urlString) {
          ImagePrefetcher.prefetch(urls: [url], max: 1)
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
      } else {
        RoundedRectangle(cornerRadius: cornerRadius)
          .fill(Color.border.opacity(0.3))
          .overlay(
            Image(systemName: "person.fill")
              .font(.system(size: size * 0.45))
              .foregroundColor(.textMuted)
          )
          .frame(width: size, height: size)
      }
    }
    .accessibilityHidden(true)
  }
}
