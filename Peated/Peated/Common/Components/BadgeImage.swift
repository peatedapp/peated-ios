import SwiftUI

struct BadgeImage: View {
  let urlString: String?
  let size: CGFloat
  let cornerRadius: CGFloat

  init(urlString: String?, size: CGFloat = 80, cornerRadius: CGFloat = 12) {
    self.urlString = urlString
    self.size = size
    self.cornerRadius = cornerRadius
  }

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: cornerRadius)
        .fill(Color.background)
        .frame(width: size, height: size)

      if let urlString, let url = URL(string: urlString) {
        CachedAsyncImage(url: url) { image in
          image
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: size, height: size)
            .clipped()
        } placeholder: {
          ProgressView()
            .frame(width: size, height: size)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
      } else {
        Image(systemName: "medal.fill")
          .font(.system(size: size * 0.5))
          .foregroundColor(.warning)
      }
    }
  }
}

