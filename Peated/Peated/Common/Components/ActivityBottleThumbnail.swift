import SwiftUI

/// The bottle image beside an activity row, or Peated's glyph when none exists.
/// Cover fit is for personal photos; catalog bottle images stay contained.
struct ActivityBottleThumbnail: View {
    enum Size {
        case activity
        case compact

        var frame: CGSize {
            switch self {
            case .activity: CGSize(width: 42, height: 58)
            case .compact: CGSize(width: 24, height: 32)
            }
        }

        var padding: CGFloat {
            switch self {
            case .activity: 4
            case .compact: 2
            }
        }
    }

    enum Fit {
        case contain
        case cover
    }

    let imageUrl: String?
    var fit: Fit = .contain
    var size: Size = .activity

    var body: some View {
        Group {
            if let imageUrl, let url = URL(string: imageUrl) {
                CachedAsyncImage(url: url) { image in
                    // The content closure is not a view builder, so branch inside a Group.
                    Group {
                        if fit == .cover {
                            image
                                .resizable()
                                .scaledToFill()
                        } else {
                            image
                                .resizable()
                                .scaledToFit()
                                .padding(size.padding)
                        }
                    }
                } placeholder: {
                    Color.clear
                }
                .task(id: imageUrl) {
                    ImagePrefetcher.prefetch(urls: [url], max: 1)
                }
                .frame(width: size.frame.width, height: size.frame.height)
                .background(Color.imageBackground)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                        .stroke(Color.border, lineWidth: 1)
                )
            } else {
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                    .fill(Color.surfaceSubtle)
                    .frame(width: size.frame.width, height: size.frame.height)
                    .overlay(
                        Image(systemName: "wineglass")
                            .font(.system(size: size == .compact ? 12 : 18))
                            .foregroundColor(.textSecondary)
                    )
            }
        }
        .accessibilityHidden(true)
    }
}
