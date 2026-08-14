import SwiftUI

struct LibraryFavoritesSkeleton: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(0 ..< 6, id: \.self) { _ in
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.border.opacity(0.3))
                            .frame(width: 60, height: 80)

                        VStack(alignment: .leading, spacing: 6) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.border.opacity(0.25))
                                .frame(width: 180, height: 12)
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.border.opacity(0.2))
                                .frame(width: 120, height: 10)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .redacted(reason: .placeholder)
                    .shimmer()
                }
            }
            .padding(.top, 8)
        }
    }
}
