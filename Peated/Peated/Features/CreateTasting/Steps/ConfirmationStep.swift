import PeatedCore
import SwiftUI

struct ConfirmationStep: View {
    @ObservedObject var viewModel: CreateTastingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Looking good?")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.text)

                    Text("Quick check before posting")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
                .padding(.horizontal)
                .padding(.top)

                // Tasting Preview - Clean card style
                TastingPreviewCard(viewModel: viewModel)
                    .padding(.horizontal)
            }
            .padding(.bottom, 100) // Space for navigation buttons
        }
        .background(Color.background)
    }
}

// MARK: - Tasting Preview Card (Redesigned)

struct TastingPreviewCard: View {
    let viewModel: CreateTastingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card content
            VStack(alignment: .leading, spacing: 12) {
                // User header (simulated)
                HStack(spacing: 10) {
                    Circle()
                        .fill(Color.border.opacity(0.2))
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.textSecondary.opacity(0.5))
                        )
                        .frame(width: 32, height: 32)

                    Text("You")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.text)

                    Text("•")
                        .font(.system(size: 14))
                        .foregroundColor(.textSecondary.opacity(0.5))

                    Text("now")
                        .font(.system(size: 14))
                        .foregroundColor(.textSecondary)

                    Spacer()

                    if let band = viewModel.ratingBand {
                        TastingRatingView(band: band, showRange: true, fontSize: 12)
                    }
                }

                // Bottle info card-within-card
                if let bottle = viewModel.selectedBottle {
                    HStack(spacing: 12) {
                        // Bottle image or icon
                        BottleImage(imageUrl: bottle.imageUrl)
                            .frame(width: 28, height: 36)

                        VStack(alignment: .leading, spacing: 3) {
                            // Bottle name
                            Text(bottle.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.text)
                                .lineLimit(1)

                            // Brand • Category on one line
                            HStack(spacing: 4) {
                                Text(bottle.brandName)
                                    .font(.system(size: 14))
                                    .foregroundColor(.textSecondary)
                                    .lineLimit(1)

                                Text("•")
                                    .font(.system(size: 14))
                                    .foregroundColor(.textSecondary.opacity(0.5))

                                Text(bottle.category ?? "Whisky")
                                    .font(.system(size: 14))
                                    .foregroundColor(.textSecondary)
                                    .lineLimit(1)
                            }
                        }

                        Spacer()
                    }
                    .padding(12)
                    .background(Color.formSurface.opacity(0.6))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.border.opacity(0.3), lineWidth: 1)
                    )
                }

                // Notes
                if !viewModel.notes.isEmpty {
                    Text(viewModel.notes)
                        .font(.system(size: 14))
                        .foregroundColor(.text.opacity(0.9))
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }

                // Tags
                if !viewModel.selectedTags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(viewModel.selectedTags), id: \.self) { tag in
                                Text("#\(tag)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.brand)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.brand.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                // Photo thumbnails
                if !viewModel.photos.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(viewModel.photos.enumerated()), id: \.offset) { _, photo in
                                Image(uiImage: photo)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                        }
                    }
                }

                // Additional info (compact)
                HStack(spacing: 16) {
                    // Serving style
                    if let servingStyle = viewModel.servingStyle {
                        HStack(spacing: 4) {
                            Image(systemName: "drop")
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)
                            Text(servingStyle.displayName)
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)
                        }
                    }

                    // Location
                    if let location = viewModel.selectedLocation {
                        HStack(spacing: 4) {
                            Image(systemName: "location")
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)
                            Text(location.name)
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)
                                .lineLimit(1)
                        }
                    } else if viewModel.isDrinkingAtHome {
                        HStack(spacing: 4) {
                            Image(systemName: "house")
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)
                            Text("At Home")
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)
                        }
                    }

                    Spacer()
                }
                .padding(.top, 4)
            }
            .padding()
            .background(Color.formSurface)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.border.opacity(0.3), lineWidth: 1)
            )
        }
    }
}
