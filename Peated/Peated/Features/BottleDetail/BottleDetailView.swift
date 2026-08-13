import PeatedCore
import SwiftUI

struct BottleDetailView: View {
    let bottleId: String
    let bottleName: String?
    let seed: Bottle?

    @State private var model: BottleDetailModel
    @State private var showingCreateTasting = false
    @State private var showingShareSheet = false
    @State private var isDescriptionExpanded = false
    @State private var showingHeroImageViewer = false

    init(bottleId: String, bottleName: String? = nil, seed: Bottle? = nil) {
        self.bottleId = bottleId
        self.bottleName = bottleName
        self.seed = seed
        _model = State(initialValue: BottleDetailModel(bottleId: bottleId, seed: seed))
    }

    var body: some View {
        Group {
            switch model.state {
            case .loading:
                loadingView
            case let .loaded(bottle):
                loadedView(bottle)
            case let .error(message):
                errorView(message)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingShareSheet) {
            if model.bottle != nil {
                ShareSheet(activityItems: [URL(string: "https://peated.com/bottles/\(bottleId)")!])
            }
        }
        .task {
            await model.loadBottle()
        }
        .sheet(isPresented: $showingCreateTasting) {
            if let bottle = model.bottle {
                // Pass preselected bottle so step 1 (selection) is skipped
                CreateTastingFlow(preselectedBottle: bottle, onSuccess: {
                    // Refresh to show new tasting
                    Task {
                        await model.refresh()
                    }
                })
            }
        }
        .scrollContentBackground(.hidden)
        .refreshable {
            await model.refresh()
        }
        .screenBackground()
        .navigationChrome()
    }

    // MARK: - Loading View

    private var loadingView: some View {
        BottleDetailSkeleton()
    }

    // MARK: - Loaded View

    private func loadedView(_ bottle: Bottle) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // Hero image with in-image title (if available)
                heroSection(bottle)

                // Fallback name card when no image
                if bottle.imageUrl == nil {
                    nameCardSection(bottle)
                        .padding(.horizontal)
                        .padding(.top, 16)
                }

                // Action buttons
                actionButtons(bottle)
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .padding(.bottom, 12)

                // Stats and about sections
                aboutSection(bottle)
                    .padding(.bottom, 20)

                // Recent activity
                if !model.recentTastings.isEmpty {
                    Divider()
                        .padding(.bottom, 20)
                    recentActivitySection
                }

                // Similar bottles
                if !model.similarBottles.isEmpty {
                    Divider()
                        .padding(.vertical, 20)
                    similarBottlesSection
                }
            }
        }
        .scrollContentBackground(.hidden)
        .refreshable {
            await model.refresh()
        }
    }

    // MARK: - Hero Section

    @ViewBuilder
    private func heroSection(_ bottle: Bottle) -> some View {
        if let imageUrl = bottle.imageUrl, let url = URL(string: imageUrl) {
            CachedAsyncImage(url: url) { image in
                ZStack(alignment: .bottom) {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .frame(height: 390)
                        .clipped()

                    // Dark gradient overlay for text legibility
                    LinearGradient(
                        gradient: Gradient(colors: [Color.clear, Color.black.opacity(0.95)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    // Title + brand link + status icons
                    VStack(spacing: 8) {
                        Text(bottle.fullName)
                            .font(.peatedDisplaySerifLarge)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)

                        NavigationLink(
                            destination: EntityDetailView(
                                entityId: bottle.brand.id,
                                entityName: bottle.brand.name,
                                seed: Entity(
                                    id: bottle.brand.id,
                                    name: bottle.brand.name,
                                    type: .brand,
                                    imageUrl: nil,
                                    totalBottles: 0,
                                    totalTastings: 0
                                )
                            )
                        ) {
                            HStack(spacing: 4) {
                                Image(systemName: "building.2")
                                    .font(.system(size: 10))
                                Text(bottle.brandName)
                            }
                            .font(.system(size: DesignSystem.FontSize.small))
                            .foregroundColor(.white.opacity(0.9))
                        }
                        .buttonStyle(.plain)

                        // Status badges with labels for clarity (hero)
                        if bottle.hasTasted || bottle.isFavorite {
                            HStack(spacing: 10) {
                                if bottle.hasTasted {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.9))
                                        Text("Tasted")
                                            .font(.system(size: DesignSystem.FontSize.small))
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                }
                                if bottle.hasTasted, bottle.isFavorite {
                                    Text("•")
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                if bottle.isFavorite {
                                    HStack(spacing: 4) {
                                        Image(systemName: "star.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.9))
                                        Text("Favorited")
                                            .font(.system(size: DesignSystem.FontSize.small))
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity)
                    .background(Color.black)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
                }
                .contentShape(Rectangle())
                .onTapGesture { showingHeroImageViewer = true }
                .imageViewer(imageUrl: bottle.imageUrl, isPresented: $showingHeroImageViewer)
                .padding(.top, 0)
            } placeholder: {
                EmptyView()
            }
        }
    }

    // MARK: - Name Banner (no-image fallback)

    private func nameCardSection(_ bottle: Bottle) -> some View {
        VStack(spacing: 8) {
            Text(bottle.fullName)
                .font(.peatedDisplaySerifLarge)
                .foregroundColor(.text)
                .multilineTextAlignment(.center)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)

            NavigationLink(
                destination: EntityDetailView(
                    entityId: bottle.brand.id,
                    entityName: bottle.brand.name,
                    seed: Entity(
                        id: bottle.brand.id,
                        name: bottle.brand.name,
                        type: .brand,
                        imageUrl: nil,
                        totalBottles: 0,
                        totalTastings: 0
                    )
                )
            ) {
                HStack(spacing: 4) {
                    Image(systemName: "building.2")
                        .font(.system(size: 10))
                    Text(bottle.brandName)
                }
                .font(.system(size: DesignSystem.FontSize.small))
                .foregroundColor(.textSecondary)
            }
            .buttonStyle(.plain)

            // Status badges with labels for clarity (no-image fallback)
            if bottle.hasTasted || bottle.isFavorite {
                HStack(spacing: 10) {
                    if bottle.hasTasted {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)
                            Text("Tasted")
                                .font(.system(size: DesignSystem.FontSize.small))
                                .foregroundColor(.textSecondary)
                        }
                    }
                    if bottle.hasTasted, bottle.isFavorite {
                        Text("•")
                            .foregroundColor(.textSecondary)
                    }
                    if bottle.isFavorite {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)
                            Text("Favorited")
                                .font(.system(size: DesignSystem.FontSize.small))
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
    }

    // Title section replaced by headerSection above

    // MARK: - Action Buttons

    private func actionButtons(_ bottle: Bottle) -> some View {
        HStack(spacing: 12) {
            // Primary CTA
            Button(action: { showingCreateTasting = true }) {
                Label("Record Tasting", systemImage: "plus.circle")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.brand)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.brand.opacity(0.14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.brand.opacity(0.2), lineWidth: 1)
                    )
                    .cornerRadius(12)
            }

            // Share button
            Button(action: { showingShareSheet = true }) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 20))
                    .fontWeight(.medium)
                    .foregroundColor(.text)
                    .frame(width: 50, height: 50)
                    .background(Color.border.opacity(0.3))
                    .cornerRadius(12)
            }

            // Favorite button
            Button(action: { Task { await model.toggleFavorite() } }) {
                Image(systemName: bottle.isFavorite ? "star.fill" : "star")
                    .font(.system(size: 20))
                    .fontWeight(.medium)
                    .foregroundColor(bottle.isFavorite ? .brand : .text)
                    .frame(width: 50, height: 50)
                    .background(Color.border.opacity(0.3))
                    .cornerRadius(12)
                    .accessibilityLabel(bottle.isFavorite ? "Unfavorite" : "Favorite")
            }
        }
    }

    // MARK: - About Section

    private func aboutSection(_ bottle: Bottle) -> some View {
        VStack(spacing: 20) {
            // Stats section (similar to EntityDetailView)
            statsSection(bottle)
                .padding(.horizontal)

            // Description section if available
            if let description = bottle.description, !description.isEmpty {
                descriptionSection(bottle)
                    .padding(.horizontal)
            }

            // Bottle characteristics and rating if present
            if bottle.caskStrength || bottle.singleCask || bottle.totalRatings > 0 {
                characteristicsSection(bottle)
                    .padding(.horizontal)
            }
        }
    }

    // MARK: - Stats Section

    private func statsSection(_ bottle: Bottle) -> some View {
        HStack(spacing: 0) {
            // Style (formerly Category)
            if let category = bottle.category {
                VStack(spacing: 8) {
                    Text(category.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.system(size: DesignSystem.FontSize.small))
                        .fontWeight(.semibold)
                        .foregroundColor(.text)
                        .lineLimit(1)
                    Text("Style")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }

            if bottle.category != nil, bottle.abv != nil || bottle.statedAge != nil {
                Divider()
                    .frame(height: 40)
                    .background(Color.border.opacity(0.3))
            }

            // ABV
            if let abv = bottle.abv {
                VStack(spacing: 8) {
                    Text("\(abv, specifier: "%.1f")%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.text)
                    Text("ABV")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }

            if bottle.abv != nil, bottle.statedAge != nil {
                Divider()
                    .frame(height: 40)
                    .background(Color.border.opacity(0.3))
            }

            // Age
            if let age = bottle.statedAge {
                VStack(spacing: 8) {
                    Text("\(age)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.text)
                    Text("Years")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }

            // Rating if exists
            if bottle.totalRatings > 0, bottle.category == nil, bottle.abv == nil, bottle.statedAge == nil {
                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.brand)
                        Text(String(format: "%.1f", bottle.avgRating))
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.text)
                    }
                    Text("\(bottle.totalRatings) ratings")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 12)
        .background(Color.surface.opacity(0.5))
        .cornerRadius(DesignSystem.CornerRadius.medium)
    }

    // MARK: - Description Section

    private func descriptionSection(_ bottle: Bottle) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ABOUT")
                .font(.system(size: DesignSystem.FontSize.small))
                .fontWeight(.semibold)
                .foregroundColor(.textSecondary)

            VStack(alignment: .leading, spacing: 4) {
                Text(bottle.description ?? "")
                    .font(.system(size: DesignSystem.FontSize.body))
                    .foregroundColor(.text)
                    .lineLimit(isDescriptionExpanded ? nil : 3)
                    .fixedSize(horizontal: false, vertical: true)

                // Only show button if text is long enough to be truncated
                if let description = bottle.description, description.count > 150 {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isDescriptionExpanded.toggle()
                        }
                    }) {
                        Text(isDescriptionExpanded ? "Show less" : "Read more")
                            .font(.system(size: DesignSystem.FontSize.small))
                            .fontWeight(.medium)
                            .foregroundColor(.brand)
                    }
                    .padding(.top, 2)
                }
            }
        }
    }

    // MARK: - Characteristics Section

    private func characteristicsSection(_ bottle: Bottle) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CHARACTERISTICS")
                .font(.system(size: DesignSystem.FontSize.small))
                .fontWeight(.semibold)
                .foregroundColor(.textSecondary)

            VStack(alignment: .leading, spacing: 8) {
                // Cask properties
                if bottle.caskStrength || bottle.singleCask {
                    HStack(spacing: 12) {
                        if bottle.caskStrength {
                            Label("Cask Strength", systemImage: "checkmark.circle.fill")
                                .font(.system(size: DesignSystem.FontSize.small))
                                .foregroundColor(.success)
                        }

                        if bottle.singleCask {
                            Label("Single Cask", systemImage: "checkmark.circle.fill")
                                .font(.system(size: DesignSystem.FontSize.small))
                                .foregroundColor(.success)
                        }
                    }
                }

                // Community rating
                if bottle.totalRatings > 0 {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.brand)
                            Text(String(format: "%.1f", bottle.avgRating))
                                .font(.system(size: 18))
                                .fontWeight(.semibold)
                                .foregroundColor(.text)
                            Text("average rating")
                                .font(.system(size: DesignSystem.FontSize.small))
                                .foregroundColor(.textSecondary)
                        }

                        Text("\(bottle.totalRatings) \(bottle.totalRatings == 1 ? "rating" : "ratings") from the community")
                            .font(.system(size: DesignSystem.FontSize.small))
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.surface.opacity(0.5))
                    .cornerRadius(8)
                }
            }
        }
    }

    // MARK: - Recent Activity Section

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)

                Spacer()
            }
            .padding(.horizontal)

            VStack(spacing: 0) {
                ForEach(model.recentTastings.prefix(3)) { tasting in
                    VStack(spacing: 0) {
                        TastingFeedCard(
                            tasting: tasting,
                            showBottle: false, // Hide bottle info since we're on the bottle page
                            onToast: {
                                // TODO: Implement toast functionality
                            },
                            onComment: {
                                // TODO: Navigate to tasting detail
                            },
                            onUserTap: {
                                // TODO: Navigate to user profile
                            },
                            onBottleTap: {
                                // No-op since we're already on the bottle page
                            }
                        )
                        // Avoid extra inset; TastingFeedCard already pads horizontally

                        // Add divider between items
                        if tasting != model.recentTastings.prefix(3).last {
                            Divider()
                                .background(Color.border.opacity(0.2))
                        }
                    }
                }
            }
        }
    }

    // MARK: - Similar Bottles Section

    private var similarBottlesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Similar Bottles")
                .font(.headline)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(model.similarBottles) { bottle in
                        NavigationLink(destination: BottleDetailView(bottleId: bottle.id, bottleName: bottle.fullName)) {
                            SimilarBottleCard(bottle: bottle)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Error View

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.warning)

            Text("Unable to load bottle")
                .font(.title3)
                .fontWeight(.semibold)

            Text(message)
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)

            Button(action: {
                Task {
                    await model.loadBottle()
                }
            }) {
                Text("Try Again")
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.onBrand)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.brand)
                    .cornerRadius(20)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Supporting Views

struct SimilarBottleCard: View {
    let bottle: Bottle

    var body: some View {
        VStack(spacing: 8) {
            // Bottle image
            BottleImage(imageUrl: bottle.imageUrl)
                .frame(width: 80, height: 120)

            VStack(spacing: 4) {
                Text(bottle.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.text)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                if bottle.totalRatings > 0 {
                    HStack(spacing: 2) {
                        ForEach(1 ... 5, id: \.self) { star in
                            Image(systemName: star <= Int(bottle.avgRating.rounded()) ? "star.fill" : "star")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                        }
                    }
                    Text(String(format: "%.1f", bottle.avgRating))
                        .font(.caption2)
                        .foregroundColor(.textSecondary)
                }
            }
        }
        .frame(width: 120)
        .padding()
        .background(Color.surface)
        .cornerRadius(12)
    }
}

// MARK: - ShareSheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context _: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_: UIActivityViewController, context _: Context) {}
}
