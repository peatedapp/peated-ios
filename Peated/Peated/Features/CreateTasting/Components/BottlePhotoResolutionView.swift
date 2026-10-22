import PeatedCore
import SwiftUI

struct BottlePhotoResolutionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: BottlePhotoResolutionViewModel
    @State private var showingManualEntry = false
    @State private var isSlow = false

    let image: UIImage
    let onBottleResolved: (Bottle, String) -> Void
    let onSearch: (String) -> Void

    init(
        image: UIImage,
        repository: any BottlePhotoRepositoryProtocol =
            BottlePhotoIdentificationRepository(),
        onBottleResolved: @escaping (Bottle, String) -> Void,
        onSearch: @escaping (String) -> Void
    ) {
        self.image = image
        self.onBottleResolved = onBottleResolved
        self.onSearch = onSearch
        _viewModel = StateObject(wrappedValue: BottlePhotoResolutionViewModel(repository: repository))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 240)
                        .frame(maxWidth: .infinity)
                        .clipped()
                        .cornerRadius(12)
                        .accessibilityLabel("Your bottle photo")

                    content
                }
                .padding()
            }
            .background(Color.background)
            .navigationTitle("Identify Bottle")
            .navigationBarTitleDisplayMode(.inline)
            .navigationChrome()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Unable to Continue", isPresented: errorBinding) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage ?? "Something went wrong.")
            }
            .sheet(isPresented: $showingManualEntry) {
                ManualBottleEntryView(initialInput: viewModel.identification?.manualBottleInput) { bottle in
                    guard let pendingImageId = viewModel.identification?.pendingImageId else { return }
                    resolve(bottle, pendingImageId: pendingImageId)
                }
            }
            .task {
                await identifyPhoto()
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isIdentifying {
            identifyingContent
        } else if let identification = viewModel.identification {
            identificationContent(identification)
        } else {
            VStack(spacing: 16) {
                Text("We couldn't read this photo")
                    .font(.headline)
                Text("Try again with the front label filling most of the frame.")
                    .font(.subheadline)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                actionButton(title: "Try Again", systemImage: "arrow.clockwise") {
                    Task { await identifyPhoto() }
                }
                secondaryButton(title: "Search by Name", systemImage: "magnifyingglass") {
                    search(with: "")
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
    }

    private var identifyingContent: some View {
        VStack(spacing: 20) {
            VStack(spacing: 14) {
                ProgressView()
                    .scaleEffect(1.2)
                    .accessibilityHidden(true)
                Text(viewModel.statusText)
                    .font(.headline)
                    .accessibilityAddTraits(.updatesFrequently)
                if isSlow {
                    Text("This one is taking a while.")
                        .font(.subheadline)
                        .foregroundColor(.textSecondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)

            if !viewModel.likelyMatches.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Possible matches")
                        .font(.headline)
                        .foregroundColor(.text)
                        .accessibilityAddTraits(.isHeader)
                    ForEach(viewModel.likelyMatches) { bottle in
                        Button {
                            guard let pendingImageId = viewModel.pickLikelyMatch() else { return }
                            resolve(bottle, pendingImageId: pendingImageId)
                        } label: {
                            bottleCard(bottle)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .onChange(of: viewModel.statusText) { _, status in
            AccessibilityNotification.Announcement(status).post()
        }
        .task {
            // Matches the web resolver's slow-lookup notice.
            isSlow = false
            guard await (try? Task.sleep(for: .seconds(45))) != nil else { return }
            isSlow = true
        }
    }

    @ViewBuilder
    private func identificationContent(_ identification: BottlePhotoIdentification) -> some View {
        switch identification.outcome {
        case let .matched(bottle):
            resultHeader(
                title: "Bottle found",
                description: "Confirm this is the bottle in your photo."
            )
            bottleCard(bottle)
            factsSection(identification.facts)
            actionButton(title: "Use This Bottle", systemImage: "checkmark") {
                resolve(bottle, pendingImageId: identification.pendingImageId)
            }
            searchButton(identification)
            addBottleButton()
            startOverButton()

        case let .proposed(proposal, createToken):
            resultHeader(
                title: "Bottle not in Peated",
                description: "Review the label details before creating this bottle."
            )
            proposalCard(proposal)
            factsSection(identification.facts)
            actionButton(
                title: viewModel.isCreating ? "Creating Bottle..." : "Create Bottle",
                systemImage: "plus"
            ) {
                Task {
                    guard let creation = await viewModel.createBottle(createToken: createToken) else {
                        return
                    }
                    resolve(creation.bottle, pendingImageId: identification.pendingImageId)
                }
            }
            .disabled(viewModel.isCreating)
            searchButton(identification)
            startOverButton()

        case .notFound:
            resultHeader(
                title: "We couldn't find this bottle",
                description: "We found label details, but not enough to choose an existing bottle. " +
                    "Review them before adding it to Peated."
            )
            factsSection(identification.facts)
            actionButton(title: "Add a New Bottle", systemImage: "plus") {
                showingManualEntry = true
            }
            searchButton(identification)
            startOverButton()

        case .unidentified:
            resultHeader(
                title: "We couldn't identify the bottle",
                description: "Search can still find it, or you can start over with another photo."
            )
            factsSection(identification.facts)
            actionButton(title: "Search Bottles", systemImage: "magnifyingglass") {
                search(with: identification.searchQuery)
            }
            addBottleButton()
            startOverButton()
        }
    }

    private func searchButton(_ identification: BottlePhotoIdentification) -> some View {
        secondaryButton(title: "Search Bottles", systemImage: "magnifyingglass") {
            search(with: identification.searchQuery)
        }
    }

    private func addBottleButton() -> some View {
        secondaryButton(title: "Add a New Bottle", systemImage: "plus") {
            showingManualEntry = true
        }
    }

    /// Returns to bottle selection, where the user can choose another photo.
    private func startOverButton() -> some View {
        Button {
            dismiss()
        } label: {
            Label("Start Over", systemImage: "arrow.counterclockwise")
                .fontWeight(.medium)
                .foregroundColor(.brand)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
    }

    private func resultHeader(title: String, description: String) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.text)
            Text(description)
                .font(.subheadline)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private func bottleCard(_ bottle: Bottle) -> some View {
        HStack(spacing: 12) {
            if let imageUrl = bottle.imageUrl, let url = URL(string: imageUrl) {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    Color.formSurface
                }
                .frame(width: 64, height: 80)
                .cornerRadius(8)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(bottle.fullName)
                    .font(.headline)
                    .foregroundColor(.text)
                if let age = bottle.statedAge {
                    Text("\(age) years")
                        .font(.caption)
                        .foregroundColor(.textSecondary)
                }
            }
            Spacer()
        }
        .padding()
        .background(Color.formSurface)
        .cornerRadius(12)
    }

    private func proposalCard(_ proposal: BottlePhotoProposal) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(proposal.fullName)
                .font(.headline)
                .foregroundColor(.text)
            Text("New catalog bottle")
                .font(.caption)
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.formSurface)
        .cornerRadius(12)
    }

    @ViewBuilder
    private func factsSection(_ facts: [BottlePhotoFact]) -> some View {
        if !facts.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("From the label")
                    .font(.headline)
                    .foregroundColor(.text)
                ForEach(facts) { fact in
                    HStack(alignment: .firstTextBaseline) {
                        Text(fact.label)
                            .foregroundColor(.textSecondary)
                        Spacer()
                        Text(fact.value)
                            .foregroundColor(.text)
                            .multilineTextAlignment(.trailing)
                    }
                    .font(.subheadline)
                }
            }
            .padding()
            .background(Color.formSurface)
            .cornerRadius(12)
        }
    }

    private func actionButton(
        title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .fontWeight(.medium)
                .foregroundColor(.onBrand)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.brand)
                .cornerRadius(10)
        }
    }

    private func secondaryButton(
        title: String,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .fontWeight(.medium)
                // Ink text keeps the label readable on the brand tint; brand-on-tint is below 4.5:1.
                .foregroundColor(.text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.brand.opacity(0.1))
                .cornerRadius(10)
        }
    }

    private var errorBinding: Binding<Bool> {
        Binding(
            get: { viewModel.errorMessage != nil && viewModel.identification != nil },
            set: { isPresented in
                if !isPresented {
                    viewModel.errorMessage = nil
                }
            }
        )
    }

    private func identifyPhoto() async {
        guard let imageData = image.compressedForUpload(maxSizeKB: 2048) else {
            viewModel.errorMessage = "We couldn't prepare that image for upload."
            return
        }
        await viewModel.identify(imageData: imageData)
    }

    private func resolve(_ bottle: Bottle, pendingImageId: String) {
        dismiss()
        onBottleResolved(bottle, pendingImageId)
    }

    private func search(with query: String) {
        dismiss()
        onSearch(query)
    }
}
