import SwiftUI

/// Structured skeleton for BottleDetailView that mirrors loaded layout
struct BottleDetailSkeleton: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero image placeholder (match loaded height to prevent jump)
                RoundedRectangle(cornerRadius: 0)
                    .fill(Color.border.opacity(0.25))
                    .frame(height: 390)

                VStack(spacing: 20) {
                    // Fallback name card spacing parity when no image
                    // Keep a small spacer to visually balance content after hero
                    Spacer().frame(height: 16)

                    // Stats card placeholder (3 equal segments)
                    HStack(spacing: 0) {
                        ForEach(0 ..< 3) { idx in
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

                            if idx < 2 {
                                Divider().frame(height: 40).background(Color.border.opacity(0.3))
                            }
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal)
                    .background(Color.surface.opacity(0.5))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Description placeholder block
                    VStack(alignment: .leading, spacing: 10) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.border.opacity(0.2))
                            .frame(width: 60, height: 10) // ABOUT label
                        VStack(alignment: .leading, spacing: 8) {
                            RoundedRectangle(cornerRadius: 6).fill(Color.border.opacity(0.25)).frame(height: 12)
                            RoundedRectangle(cornerRadius: 6).fill(Color.border.opacity(0.25)).frame(height: 12)
                            RoundedRectangle(cornerRadius: 6).fill(Color.border.opacity(0.25)).frame(
                                width: 180,
                                height: 12
                            )
                        }
                    }
                    .padding(.horizontal)

                    // Action buttons placeholder (Record, Share, Favorite)
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.border.opacity(0.25))
                            .frame(height: 50)
                            .frame(maxWidth: .infinity)
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.border.opacity(0.25))
                            .frame(width: 50, height: 50)
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.border.opacity(0.25))
                            .frame(width: 50, height: 50)
                    }
                    .padding(.horizontal)

                    // Recent activity skeleton list (3 items)
                    VStack(alignment: .leading, spacing: 12) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.border.opacity(0.2))
                            .frame(width: 130, height: 14) // Section title
                            .padding(.horizontal)

                        VStack(spacing: 0) {
                            ForEach(0 ..< 3) { i in
                                VStack(spacing: 0) {
                                    SkeletonTastingRowCompact()
                                    if i < 2 {
                                        Divider().background(Color.border.opacity(0.2))
                                    }
                                }
                            }
                        }
                    }

                    // Similar bottles skeleton carousel
                    VStack(alignment: .leading, spacing: 12) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.border.opacity(0.2))
                            .frame(width: 140, height: 14) // Section title
                            .padding(.horizontal)
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(0 ..< 4) { _ in
                                    VStack(spacing: 8) {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.border.opacity(0.25))
                                            .frame(width: 80, height: 120)
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.border.opacity(0.25))
                                            .frame(width: 100, height: 10)
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(Color.border.opacity(0.2))
                                            .frame(width: 60, height: 8)
                                    }
                                    .frame(width: 120)
                                    .padding()
                                    .background(Color.surface)
                                    .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    Spacer(minLength: 16)
                }
            }
            .redacted(reason: .placeholder)
            .shimmer()
        }
        .scrollContentBackground(.hidden)
        .background(Color.background)
    }
}

/// Compact tasting row skeleton approximating recent activity items
private struct SkeletonTastingRowCompact: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.border.opacity(0.2))
                .frame(width: 48, height: 64)
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4).fill(Color.border.opacity(0.25)).frame(width: 180, height: 12)
                RoundedRectangle(cornerRadius: 4).fill(Color.border.opacity(0.2)).frame(width: 120, height: 10)
                RoundedRectangle(cornerRadius: 4).fill(Color.border.opacity(0.2)).frame(width: 100, height: 10)
                HStack(spacing: 8) {
                    Circle().fill(Color.border.opacity(0.2)).frame(width: 18, height: 18)
                    RoundedRectangle(cornerRadius: 4).fill(Color.border.opacity(0.2)).frame(width: 120, height: 10)
                }
                .padding(.top, 4)
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}
