import SwiftUI

// MARK: - FormSection
// A card-like form section that avoids SwiftUI Form gray backgrounds.
struct FormSection<Content: View>: View {
  let title: String?
  @ViewBuilder let content: Content

  init(_ title: String? = nil, @ViewBuilder content: () -> Content) {
    self.title = title
    self.content = content()
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      if let title, !title.isEmpty {
        Text(title)
          .font(.caption)
          .foregroundColor(.textSecondary)
          .padding(.horizontal, 4)
      }

      VStack(alignment: .leading, spacing: 12) {
        content
      }
      .padding(12)
      .background(Color.surface)
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(Color.border.opacity(0.3), lineWidth: 1)
      )
      .cornerRadius(12)
    }
    .padding(.horizontal)
  }
}

