import SwiftUI

struct ProfileSkeleton: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Circle()
                        .fill(Color.border.opacity(0.25))
                        .frame(width: 100, height: 100)

                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.border.opacity(0.25))
                        .frame(width: 160, height: 16)

                    // Role badge placeholder
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.border.opacity(0.25))
                            .frame(width: 80, height: 22)
                    }
                }
                .padding(.top, 20)
                .padding(.horizontal)

                // Stats
                HStack(spacing: 0) {
                    ForEach(0 ..< 3) { idx in
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 6).fill(Color.border.opacity(0.25)).frame(
                                width: 50,
                                height: 16
                            )
                            RoundedRectangle(cornerRadius: 6).fill(Color.border.opacity(0.2)).frame(
                                width: 60,
                                height: 10
                            )
                        }
                        .frame(maxWidth: .infinity)
                        if idx < 2 {
                            Divider().frame(height: 40).background(Color.border.opacity(0.3))
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 16)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.border.opacity(0.2), lineWidth: 1))
                .padding(.horizontal)

                // Achievements section
                VStack(alignment: .leading, spacing: 12) {
                    RoundedRectangle(cornerRadius: 6).fill(Color.border.opacity(0.2)).frame(width: 120, height: 14)
                        .padding(.horizontal)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(0 ..< 4) { _ in
                                VStack(spacing: 6) {
                                    RoundedRectangle(cornerRadius: 12).fill(Color.surface).frame(width: 80, height: 80)
                                    RoundedRectangle(cornerRadius: 6).fill(Color.border.opacity(0.25)).frame(
                                        width: 60,
                                        height: 10
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 20)

                // Tabs
                HStack(spacing: 0) {
                    ForEach([(0, "Activity"), (1, "Library")], id: \.0) { pair in
                        let idx = pair.0
                        VStack(spacing: 0) {
                            RoundedRectangle(cornerRadius: 6).fill(Color.border.opacity(0.25)).frame(
                                width: 80,
                                height: 12
                            ).frame(maxWidth: .infinity).padding(.vertical, 12)
                            Rectangle().fill(idx == 0 ? Color.brand.opacity(0.6) : Color.clear).frame(height: 2)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                .overlay(Rectangle().fill(Color.border.opacity(0.2)).frame(height: 1), alignment: .bottom)

                // Activity list skeleton (2 items)
                VStack(spacing: 0) {
                    ForEach(0 ..< 2) { i in
                        VStack(spacing: 0) {
                            SkeletonTastingCard()
                            if i < 1 {
                                Divider().background(Color.border.opacity(0.2))
                            }
                        }
                    }
                }

                // Library skeleton list (2 rows)
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(0 ..< 2) { _ in
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 8).fill(Color.border.opacity(0.3)).frame(
                                width: 60,
                                height: 80
                            )
                            VStack(alignment: .leading, spacing: 6) {
                                RoundedRectangle(cornerRadius: 6).fill(Color.border.opacity(0.25)).frame(
                                    width: 160,
                                    height: 12
                                )
                                RoundedRectangle(cornerRadius: 6).fill(Color.border.opacity(0.2)).frame(
                                    width: 120,
                                    height: 10
                                )
                            }
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
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
