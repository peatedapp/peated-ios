import PeatedCore
import SwiftUI

struct BottleStatusIcons: View {
    let bottleId: String
    @State private var isLibrary: Bool = false
    @State private var hasTasted: Bool = false

    var body: some View {
        HStack(spacing: 6) {
            if hasTasted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
                    .accessibilityLabel("Tasted")
            }
            if isLibrary {
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.textSecondary)
                    .accessibilityLabel("In Library")
            }
        }
        .task(id: bottleId) {
            if let (bottle, _) = await NormalizedStore.shared.get(.bottle(bottleId), as: Bottle.self) {
                isLibrary = bottle.isLibrary
                hasTasted = bottle.hasTasted
            } else {
                isLibrary = false
                hasTasted = false
            }
        }
    }
}
