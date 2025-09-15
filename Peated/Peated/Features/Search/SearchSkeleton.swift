import SwiftUI

struct SearchResultsSkeleton: View {
  var body: some View {
    ScrollView {
      LazyVStack(spacing: 16) {
        // Bottles section
        sectionHeader(width: 120)
        cardListSkeleton(rows: 4)

        // Entities section
        sectionHeader(width: 100)
        cardListSkeleton(rows: 3)

        // Users section
        sectionHeader(width: 80)
        userListSkeleton(rows: 3)
      }
      .padding(.vertical)
      .redacted(reason: .placeholder)
      .shimmer()
    }
  }

  private func sectionHeader(width: CGFloat) -> some View {
    RoundedRectangle(cornerRadius: 6)
      .fill(Color.border.opacity(0.2))
      .frame(width: width, height: 14)
      .padding(.horizontal)
  }

  private func cardListSkeleton(rows: Int) -> some View {
    VStack(spacing: 0) {
      ForEach(0..<rows, id: \.self) { i in
        HStack(spacing: 12) {
          RoundedRectangle(cornerRadius: 8)
            .fill(Color.border.opacity(0.3))
            .frame(width: 44, height: 44)
          VStack(alignment: .leading, spacing: 6) {
            RoundedRectangle(cornerRadius: 4).fill(Color.border.opacity(0.25)).frame(width: 180, height: 12)
            RoundedRectangle(cornerRadius: 4).fill(Color.border.opacity(0.2)).frame(width: 120, height: 10)
          }
          Spacer()
        }
        .padding(.horizontal)
        if i < rows - 1 { Divider().padding(.leading, 60) }
      }
    }
    .background(Color.surface)
    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.border.opacity(0.3), lineWidth: 1))
    .cornerRadius(12)
    .padding(.horizontal)
  }

  private func userListSkeleton(rows: Int) -> some View {
    VStack(spacing: 0) {
      ForEach(0..<rows, id: \.self) { i in
        HStack(spacing: 12) {
          Circle().fill(Color.border.opacity(0.3)).frame(width: 44, height: 44)
          VStack(alignment: .leading, spacing: 6) {
            RoundedRectangle(cornerRadius: 4).fill(Color.border.opacity(0.25)).frame(width: 140, height: 12)
            RoundedRectangle(cornerRadius: 4).fill(Color.border.opacity(0.2)).frame(width: 100, height: 10)
          }
          Spacer()
          RoundedRectangle(cornerRadius: 10).fill(Color.border.opacity(0.25)).frame(width: 70, height: 24)
        }
        .padding(.horizontal)
        if i < rows - 1 { Divider().padding(.leading, 60) }
      }
    }
    .background(Color.surface)
    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.border.opacity(0.3), lineWidth: 1))
    .cornerRadius(12)
    .padding(.horizontal)
  }
}

