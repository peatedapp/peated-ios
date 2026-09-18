import PeatedCore
import SwiftUI

struct BottleDetailView: View {
    let bottleId: String
    let bottleName: String?
    let seed: Bottle?
    private let navigationPath: Binding<NavigationPath>?

    @State private var model: BottleDetailModel
    @State private var showingCreateTasting = false
    @State private var isDescriptionExpanded = false
    @State private var showingHeroImageViewer = false

    init(
        bottleId: String,
        bottleName: String? = nil,
        seed: Bottle? = nil,
        navigationPath: Binding<NavigationPath>? = nil
    ) {
        self.bottleId = bottleId
        self.bottleName = bottleName
        self.seed = seed
        self.navigationPath = navigationPath
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
}

extension BottleDetailView {
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
                        .scaledToFill()
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
                        if bottle.hasTasted || bottle.isLibrary {
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
                                if bottle.hasTasted, bottle.isLibrary {
                                    Text("•")
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                if bottle.isLibrary {
                                    HStack(spacing: 4) {
                                        Image(systemName: "books.vertical.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.white.opacity(0.9))
                                        Text("In Library")
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
            if bottle.hasTasted || bottle.isLibrary {
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
                    if bottle.hasTasted, bottle.isLibrary {
                        Text("•")
                            .foregroundColor(.textSecondary)
                    }
                    if bottle.isLibrary {
                        HStack(spacing: 4) {
                            Image(systemName: "books.vertical.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.textSecondary)
                            Text("In Library")
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

            ShareLink(item: PeatedWebURL.bottle(id: bottle.id)) {
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 20))
                    .fontWeight(.medium)
                    .foregroundColor(.text)
                    .frame(width: 50, height: 50)
                    .background(Color.border.opacity(0.3))
                    .cornerRadius(12)
            }
            .accessibilityLabel("Share bottle")

            // Library button
            Button(action: {
                Task(operation: { await model.toggleLibrary() })
            }, label: {
                Image(systemName: bottle.isLibrary ? "books.vertical.fill" : "books.vertical")
                    .font(.system(size: 20))
                    .fontWeight(.medium)
                    .foregroundColor(bottle.isLibrary ? .brand : .text)
                    .frame(width: 50, height: 50)
                    .background(Color.border.opacity(0.3))
                    .cornerRadius(12)
                    .accessibilityLabel(bottle.isLibrary ? "Remove from Library" : "Save to Library")
            })
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

            BottleSupplementalDetails(bottle: bottle)
                .padding(.horizontal)
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
            if bottle.ratingSummary.presentedCount > 0,
               bottle.category == nil,
               bottle.abv == nil,
               bottle.statedAge == nil {
                VStack(spacing: 8) {
                    BottleRatingSummaryView(
                        summary: bottle.ratingSummary,
                        showCount: false,
                        fontSize: DesignSystem.FontSize.large
                    )
                    Text("\(bottle.ratingSummary.presentedCount) ratings")
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
                                Task {
                                    await model.toggleToast(for: tasting.id)
                                }
                            },
                            onComment: {
                                navigate(to: .tasting(id: tasting.id, seed: tasting))
                            },
                            onUserTap: {
                                navigate(to: .profile(
                                    id: tasting.userId,
                                    username: tasting.username,
                                    pictureUrl: tasting.userAvatarUrl
                                ))
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
                        NavigationLink(destination: BottleDetailView(
                            bottleId: bottle.id,
                            bottleName: bottle.fullName,
                            navigationPath: navigationPath
                        )) {
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

    private func navigate(to destination: TastingActivityNavigationDestination) {
        navigationPath?.wrappedValue.append(destination)
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

                if bottle.ratingSummary.presentedCount > 0 {
                    BottleRatingSummaryView(
                        summary: bottle.ratingSummary,
                        fontSize: DesignSystem.FontSize.tiny
                    )
                }
            }
        }
        .frame(width: 120)
        .padding()
        .background(Color.surface)
        .cornerRadius(12)
    }
}
