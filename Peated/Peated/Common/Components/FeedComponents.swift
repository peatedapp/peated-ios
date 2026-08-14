import PeatedCore
import SwiftUI

/// Skeleton loading card for tastings
struct SkeletonTastingCard: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Bottle image placeholder
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.border.opacity(0.2))
                .frame(width: 48, height: 64)

            VStack(alignment: .leading, spacing: 6) {
                // Bottle name
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.border.opacity(0.2))
                    .frame(width: 180, height: 14)

                // Brand
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.border.opacity(0.2))
                    .frame(width: 120, height: 12)

                // Rating
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.border.opacity(0.2))
                    .frame(width: 100, height: 12)

                // User info
                HStack {
                    Circle()
                        .fill(Color.border.opacity(0.2))
                        .frame(width: 20, height: 20)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.border.opacity(0.2))
                        .frame(width: 150, height: 12)
                }
                .padding(.top, 4)
            }

            Spacer()
        }
        .padding(16)
        .redacted(reason: .placeholder)
        .shimmer()
    }
}

/// Error banner for dismissible errors
struct ErrorBanner: View {
    let error: Error
    @Binding var isShowing: Bool

    var body: some View {
        VStack {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.onStatus)

                Text("Failed to refresh feed")
                    .font(.subheadline)
                    .foregroundColor(.onStatus)

                Spacer()

                Button(action: { isShowing = false }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.onStatus)
                        .font(.caption)
                }
            }
            .padding()
            .background(Color.danger)
            .cornerRadius(8)
            .shadow(radius: 4)
            .padding(.horizontal)
            .padding(.top, 8)

            Spacer()
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

/// Error state for empty feed
struct ErrorEmptyView: View {
    let onRefresh: () -> Void

    var body: some View {
        VStack {
            Spacer().frame(height: 100)

            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.icloud")
                    .font(.system(size: 60))
                    .foregroundColor(.textSecondary)

                Text("Unable to Load Feed")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("We couldn't load your feed. Please check your connection and try again.")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Button(action: onRefresh) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Tap to Retry")
                    }
                    .fontWeight(.medium)
                    .foregroundColor(.onBrand)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.brand)
                    .cornerRadius(25)
                }
                .padding(.top)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
