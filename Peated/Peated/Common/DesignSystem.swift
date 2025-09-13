import SwiftUI

enum DesignSystem {
  
  enum FontSize {
    static let tiny: CGFloat = 10
    static let caption: CGFloat = 11
    static let small: CGFloat = 12
    static let body: CGFloat = 14
    static let medium: CGFloat = 15
    static let title: CGFloat = 16
    static let large: CGFloat = 17
    static let headline: CGFloat = 18
    static let xLarge: CGFloat = 20
    static let xxLarge: CGFloat = 22
    static let largeTitle: CGFloat = 24
    static let avatar: CGFloat = 14
    static let icon: CGFloat = 16
    static let largeIcon: CGFloat = 40
  }
  
  enum Spacing {
    static let xxSmall: CGFloat = 3
    static let xSmall: CGFloat = 4
    static let small: CGFloat = 8
    static let medium: CGFloat = 12
    static let large: CGFloat = 16
    static let xLarge: CGFloat = 20
    static let xxLarge: CGFloat = 24
    static let cardPadding: CGFloat = 16
    static let screenPadding: CGFloat = 20
  }
  
  enum CornerRadius {
    static let small: CGFloat = 8
    static let medium: CGFloat = 10
    static let large: CGFloat = 12
    static let capsule: CGFloat = 100
  }
  
  enum ImageSize {
    static let bottleThumb = CGSize(width: 28, height: 36)
    static let bottleLarge = CGSize(width: 50, height: 70)
    static let avatar = CGSize(width: 32, height: 32)
    static let avatarLarge = CGSize(width: 48, height: 48)
    static let photoThumb = CGSize(width: 80, height: 80)
    static let photoMax: CGFloat = 200
  }
  
  enum Opacity {
    static let subtle: Double = 0.1
    static let light: Double = 0.3
    static let medium: Double = 0.5
    static let semiOpaque: Double = 0.6
    static let dimmed: Double = 0.7
    static let strong: Double = 0.8
    static let almostFull: Double = 0.9
  }
  
  enum Animation {
    static let defaultDuration: Double = 0.3
    static let quickDuration: Double = 0.2
    static let slowDuration: Double = 0.5
  }
  
  enum Border {
    static let thin: CGFloat = 1
    static let medium: CGFloat = 1.5
    static let thick: CGFloat = 2
  }
}

// MARK: - Rating Helpers
extension DesignSystem {
  static func ratingIcon(for rating: Double) -> String {
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
  
  static func isDoubleThumbsUp(_ rating: Double) -> Bool {
    return Int(rating) == 2
  }
}

// MARK: - View Extensions for Easy Access
extension View {
  func cardStyle() -> some View {
    self
      .padding(DesignSystem.Spacing.cardPadding)
      .background(Color.surface)
      .cornerRadius(DesignSystem.CornerRadius.large)
      .overlay(
        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
          .stroke(Color.border.opacity(DesignSystem.Opacity.light), lineWidth: DesignSystem.Border.thin)
      )
  }
  
  func bottleCardStyle(isSelected: Bool = false) -> some View {
    self
      .padding(DesignSystem.Spacing.medium)
      .background(Color.surface.opacity(DesignSystem.Opacity.semiOpaque))
      .cornerRadius(DesignSystem.CornerRadius.medium)
      .overlay(
        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
          .stroke(
            isSelected ? Color.brand : Color.border.opacity(DesignSystem.Opacity.light),
            lineWidth: isSelected ? DesignSystem.Border.thick : DesignSystem.Border.thin
          )
      )
  }
  
  func tagStyle() -> some View {
    self
      .font(.system(size: DesignSystem.FontSize.small))
      .foregroundColor(.brand)
      .padding(.horizontal, DesignSystem.Spacing.medium)
      .padding(.vertical, DesignSystem.Spacing.xSmall + 1) // 5
      .background(Color.brand.opacity(DesignSystem.Opacity.subtle))
      .clipShape(Capsule())
  }
}
