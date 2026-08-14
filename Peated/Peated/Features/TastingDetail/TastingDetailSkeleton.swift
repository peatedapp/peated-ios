import SwiftUI

struct TastingDetailSkeleton: View {
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Tasting card area (approximate feed card height)
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.surface)
                        .frame(height: 320)

                    // Comments header
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.border.opacity(0.2))
                        .frame(width: 100, height: 14)

                    // Comment rows
                    ForEach(0 ..< 3, id: \.self) { _ in
                        HStack(alignment: .top, spacing: 12) {
                            Circle()
                                .fill(Color.border.opacity(0.3))
                                .frame(width: 32, height: 32)
                            VStack(alignment: .leading, spacing: 8) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.border.opacity(0.25))
                                    .frame(width: 140, height: 12)
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.border.opacity(0.2))
                                    .frame(height: 36)
                            }
                        }
                    }
                }
                .padding()
                .redacted(reason: .placeholder)
                .shimmer()
            }

            Divider()

            // Comment input skeleton at bottom
            HStack(spacing: 8) {
                Circle().fill(Color.border.opacity(0.3)).frame(width: 28, height: 28)
                RoundedRectangle(cornerRadius: 8).fill(Color.border.opacity(0.25)).frame(height: 38)
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(Color.background)
    }
}
