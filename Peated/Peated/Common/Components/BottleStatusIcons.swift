import SwiftUI
import PeatedCore

struct BottleStatusIcons: View {
  let bottleId: String
  @State private var isFavorite: Bool = false
  @State private var hasTasted: Bool = false

  var body: some View {
    HStack(spacing: 6) {
      if hasTasted {
        Image(systemName: "checkmark.circle.fill")
          .font(.system(size: 12))
          .foregroundColor(.brand)
          .accessibilityLabel("Tasted")
      }
      if isFavorite {
        Image(systemName: "star.fill")
          .font(.system(size: 11))
          .foregroundColor(.brand)
          .accessibilityLabel("Favorited")
      }
    }
    .task(id: bottleId) {
      if let (bottle, _) = await NormalizedStore.shared.get(.bottle(bottleId), as: Bottle.self) {
        isFavorite = bottle.isFavorite
        hasTasted = bottle.hasTasted
      } else {
        isFavorite = false
        hasTasted = false
      }
    }
  }
}
