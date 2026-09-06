import PeatedCore
import SwiftUI

struct RatingServingStep: View {
    @ObservedObject var viewModel: CreateTastingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Rate your experience")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.text)

                    if let bottle = viewModel.selectedBottle {
                        Text("How was the \(bottle.name)?")
                            .font(.subheadline)
                            .foregroundColor(.textSecondary)
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Rating")
                            .font(.headline)
                        Spacer()
                        Text("Optional")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                    }

                    VStack(spacing: 8) {
                        ForEach(TastingRatingBand.allCases, id: \.self) { band in
                            RatingBandSelectionButton(
                                band: band,
                                selectedBand: $viewModel.ratingBand
                            )
                        }
                    }
                }

                WhiskyColorPicker(selectedColor: $viewModel.color)

                VStack(alignment: .leading, spacing: 12) {
                    Text("How did you drink it?")
                        .font(.headline)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 12) {
                        ForEach(ServingStyle.allCases, id: \.self) { style in
                            RatingServingStyleButton(
                                style: style,
                                isSelected: viewModel.servingStyle == style,
                                onTap: {
                                    withAnimation(.spring(response: 0.3)) {
                                        viewModel.servingStyle = viewModel.servingStyle == style ? nil : style
                                    }
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                }
                            )
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.top)
            .padding(.bottom, 100)
        }
        .background(Color.background)
        .scrollDismissesKeyboard(.interactively)
    }
}

private struct RatingServingStyleButton: View {
    let style: ServingStyle
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .onBrand : .brand)

                Text(style.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .onBrand : .text)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .fill(isSelected ? Color.brand : Color.formSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                            .stroke(isSelected ? Color.brand : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.05 : 1.0)
    }

    private var iconName: String {
        switch style {
        case .neat: "wineglass"
        case .rocks: "cube"
        case .water: "drop"
        }
    }
}

private struct RatingBandSelectionButton: View {
    let band: TastingRatingBand
    @Binding var selectedBand: TastingRatingBand?

    private var isSelected: Bool {
        selectedBand == band
    }

    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                selectedBand = isSelected ? nil : band
            }
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(band.displayName)
                        .font(.body.weight(.semibold))
                    Text(band.description)
                        .font(.caption.monospacedDigit())
                        .foregroundColor(isSelected ? .onBrand.opacity(0.8) : .textSecondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
            }
            .foregroundColor(isSelected ? .onBrand : .text)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, minHeight: 58)
            .background(isSelected ? Color.brand : Color.formSurface)
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                    .stroke(isSelected ? Color.brand : Color.formBorder, lineWidth: 1)
            )
            .cornerRadius(DesignSystem.CornerRadius.medium)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(band.displayName), \(band.description)")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
