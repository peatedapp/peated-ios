import SwiftUI

struct EntityDetailSkeleton: View {
  var body: some View {
    ScrollView {
      VStack(spacing: 0) {
        // Small hero avatar
        VStack(spacing: 16) {
          Circle()
            .fill(Color.border.opacity(0.25))
            .frame(width: 100, height: 100)

          // Name placeholder
          RoundedRectangle(cornerRadius: 6)
            .fill(Color.border.opacity(0.25))
            .frame(width: 180, height: 16)
        }
        .padding(.top, 24)

        // Name card spacing parity
        Spacer().frame(height: 12)

        // Stats card placeholder
        HStack(spacing: 0) {
          ForEach(0..<3) { idx in
            VStack(spacing: 8) {
              RoundedRectangle(cornerRadius: 6)
                .fill(Color.border.opacity(0.25))
                .frame(height: 18)
                .frame(maxWidth: .infinity)
              RoundedRectangle(cornerRadius: 6)
                .fill(Color.border.opacity(0.2))
                .frame(width: 60, height: 10)
            }
            .frame(maxWidth: .infinity)

            if idx < 2 { Divider().frame(height: 40).background(Color.border.opacity(0.3)) }
          }
        }
        .padding(.vertical, 12)
        .padding(.horizontal)
        .background(Color.surface.opacity(0.5))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.top, 12)

        // About placeholder
        VStack(alignment: .leading, spacing: 10) {
          RoundedRectangle(cornerRadius: 6)
            .fill(Color.border.opacity(0.2))
            .frame(width: 60, height: 10)
          VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 6).fill(Color.border.opacity(0.25)).frame(height: 12)
            RoundedRectangle(cornerRadius: 6).fill(Color.border.opacity(0.25)).frame(height: 12)
            RoundedRectangle(cornerRadius: 6).fill(Color.border.opacity(0.25)).frame(width: 200, height: 12)
          }
        }
        .padding(.horizontal)
        .padding(.top, 12)

        // Tabs placeholder
        HStack(spacing: 0) {
          ForEach([(0, "Activity"), (1, "Bottles")], id: \.0) { pair in
            let idx = pair.0
            VStack(spacing: 0) {
              RoundedRectangle(cornerRadius: 6)
                .fill(Color.border.opacity(0.25))
                .frame(width: 80, height: 12)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
              Rectangle()
                .fill(idx == 0 ? Color.brand.opacity(0.6) : Color.clear)
                .frame(height: 2)
            }
          }
        }
        .padding(.horizontal)
        .padding(.bottom, 16)
        .overlay(Rectangle().fill(Color.border.opacity(0.2)).frame(height: 1), alignment: .bottom)

        // Activity list skeleton (3 rows)
        VStack(spacing: 0) {
          ForEach(0..<3) { i in
            VStack(spacing: 0) {
              SkeletonTastingCard()
              if i < 2 { Divider().background(Color.border.opacity(0.2)) }
            }
          }
        }

        // Bottles grid skeleton
        VStack(alignment: .leading, spacing: 12) {
          LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            ForEach(0..<4) { _ in
              VStack(alignment: .leading, spacing: 8) {
                RoundedRectangle(cornerRadius: 8)
                  .fill(Color.border.opacity(0.2))
                  .aspectRatio(0.7, contentMode: .fit)
                RoundedRectangle(cornerRadius: 6)
                  .fill(Color.border.opacity(0.25))
                  .frame(height: 12)
                RoundedRectangle(cornerRadius: 6)
                  .fill(Color.border.opacity(0.2))
                  .frame(width: 100, height: 10)
              }
            }
          }
          .padding(.horizontal)
        }

        Spacer(minLength: 16)
      }
      .redacted(reason: .placeholder)
      .shimmer()
    }
    .scrollContentBackground(.hidden)
    .background(Color.background)
  }
}

