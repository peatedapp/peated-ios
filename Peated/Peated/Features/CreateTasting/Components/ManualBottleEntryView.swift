import PeatedCore
import SwiftUI

struct ManualBottleEntryView: View {
    @Environment(\.dismiss) private var dismiss
    let onBottleCreated: (Bottle) -> Void
    private let bottleRepository: any BottleRepositoryProtocol
    private let entityRepository: any EntityRepositoryProtocol

    @State private var bottleName = ""
    @State private var brandName = ""
    @State private var category: BottleCategory?
    @State private var abv = ""
    @State private var age = ""
    @State private var noAgeStatement = false
    @State private var edition = ""
    @State private var distillers: [CreateBottleInput.Distiller] = []
    @State private var singleCask = false
    @State private var caskStrength = false
    @State private var vintageYear = ""
    @State private var releaseYear = ""
    @State private var isCreating = false
    @State private var showingError = false
    @State private var errorMessage = ""
    /// The latest existing bottles that may match the draft. Kept while a newer check runs, like the web.
    @State private var candidates: [Bottle] = []
    @State private var isCheckingCandidates = false
    @State private var reviewedCandidateIds: Set<String> = []
    /// The candidates under review. Empty means the form is showing.
    @State private var reviewResults: [Bottle] = []
    /// True when the review opened from "Add", so finishing it creates the bottle.
    @State private var addAfterReview = false

    // Local focus bindings for inputs
    @FocusState private var focusName: Bool
    @FocusState private var focusBrand: Bool
    @FocusState private var focusAbv: Bool
    @FocusState private var focusAge: Bool
    @FocusState private var focusEdition: Bool
    @FocusState private var focusVintageYear: Bool
    @FocusState private var focusReleaseYear: Bool

    init(
        initialInput: CreateBottleInput? = nil,
        bottleRepository: any BottleRepositoryProtocol = BottleRepository(),
        entityRepository: any EntityRepositoryProtocol = EntityRepository(),
        onBottleCreated: @escaping (Bottle) -> Void
    ) {
        self.bottleRepository = bottleRepository
        self.entityRepository = entityRepository
        self.onBottleCreated = onBottleCreated
        _bottleName = State(initialValue: initialInput?.name ?? "")
        _brandName = State(initialValue: initialInput?.brandName ?? "")
        _category = State(initialValue: initialInput?.category)
        _abv = State(initialValue: initialInput?.abv.map { String($0) } ?? "")
        _age = State(initialValue: initialInput?.statedAge.map { String($0) } ?? "")
        _noAgeStatement = State(initialValue: initialInput?.noAgeStatement ?? false)
        _edition = State(initialValue: initialInput?.edition ?? "")
        _distillers = State(initialValue: initialInput?.distillers ?? [])
        _singleCask = State(initialValue: initialInput?.singleCask ?? false)
        _caskStrength = State(initialValue: initialInput?.caskStrength ?? false)
        _vintageYear = State(initialValue: initialInput?.vintageYear.map { String($0) } ?? "")
        _releaseYear = State(initialValue: initialInput?.releaseYear.map { String($0) } ?? "")
    }

    private static let scrollTopId = "top"

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        if isReviewingCandidates {
                            candidateReviewSection
                        } else {
                            if candidateInput != nil, !unreviewedCandidates.isEmpty {
                                BottleCreateCandidateSummary(
                                    count: unreviewedCandidates.count,
                                    loading: isCheckingCandidates,
                                    newSinceReview: !reviewedCandidateIds.isEmpty,
                                    onReview: { openCandidateReview(addAfterReview: false) }
                                )
                                .padding(.horizontal)
                            }
                            basicInfoSection
                            madeBySection
                            detailsSection
                            datesSection
                            productionSection
                        }
                    }
                    .padding(.vertical)
                    .id(Self.scrollTopId)
                }
                .onChange(of: isReviewingCandidates) {
                    proxy.scrollTo(Self.scrollTopId, anchor: .top)
                }
            }
            .navigationTitle(isReviewingCandidates ? "Is it already on Peated?" : "Add Bottle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isReviewingCandidates {
                        Button("Back") {
                            closeCandidateReview()
                        }
                    } else {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    if !isReviewingCandidates {
                        Button(addButtonTitle) {
                            addBottle()
                        }
                        .fontWeight(.medium)
                        .disabled(!isValid || isCreating || isCheckingCandidates)
                        .accessibilityHint(isCheckingCandidates ? "Checking existing bottles…" : "")
                    }
                }
            }
            .task(id: candidateInput) {
                await checkCandidates(candidateInput)
            }
            .overlay {
                if isCreating {
                    Color.overlay
                        .ignoresSafeArea()
                        .overlay {
                            ProgressView("Adding bottle…")
                                .padding()
                                .background(Color.background)
                                .cornerRadius(DesignSystem.CornerRadius.medium)
                        }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
            .background(Color.background)
            .navigationChrome()
        }
    }

    // MARK: - Sections

    private var basicInfoSection: some View {
        FormSection("Bottle") {
            TextInput(
                label: "Brand",
                placeholder: "Laphroaig",
                text: $brandName,
                leadingSystemImage: "building.2",
                keyboard: .default,
                submitLabel: .next,
                autocorrection: true,
                capitalization: .words,
                helper: "The main label the bottle is sold under.",
                onSubmit: { focusName = true },
                isFocused: $focusBrand
            )

            TextInput(
                label: "Bottle name",
                placeholder: "12-year-old",
                text: $bottleName,
                leadingSystemImage: "wineglass",
                isSecure: false,
                keyboard: .default,
                submitLabel: .next,
                autocorrection: true,
                capitalization: .words,
                helper: "Leave the brand out of the name.",
                onSubmit: {
                    if noAgeStatement {
                        focusAbv = true
                    } else {
                        focusAge = true
                    }
                },
                isFocused: $focusName
            )

            categoryPickerRow
        }
    }

    private var detailsSection: some View {
        FormSection("Release") {
            TextInput(
                label: "Age statement (optional)",
                placeholder: "12",
                text: $age,
                leadingSystemImage: "clock",
                unit: "years",
                keyboard: .numberPad,
                submitLabel: .next,
                disabled: noAgeStatement,
                error: ageError,
                onSubmit: { focusAbv = true },
                isFocused: $focusAge
            )

            switchRow(
                "No age statement (NAS)",
                description: "The label does not state an age.",
                isOn: $noAgeStatement
            )
            .onChange(of: noAgeStatement) { _, isOn in
                if isOn {
                    age = ""
                    focusAge = false
                }
            }

            TextInput(
                label: "Alcohol (optional)",
                placeholder: "40.5",
                text: $abv,
                leadingSystemImage: "percent",
                unit: "% ABV",
                keyboard: .decimalPad,
                submitLabel: .next,
                error: abvError,
                onSubmit: { focusEdition = true },
                isFocused: $focusAbv
            )

            TextInput(
                label: "Edition or batch (optional)",
                placeholder: "Batch 24",
                text: $edition,
                leadingSystemImage: "number",
                submitLabel: .next,
                capitalization: .words,
                onSubmit: { focusVintageYear = true },
                isFocused: $focusEdition
            )
        }
    }

    private var madeBySection: some View {
        FormSection("Made by") {
            VStack(alignment: .leading, spacing: 6) {
                Text("Distilled by (optional)")
                    .font(.caption)
                    .foregroundColor(.textSecondary)

                ForEach(distillers, id: \.self) { distiller in
                    HStack(spacing: 8) {
                        Image(systemName: "building.columns")
                            .foregroundColor(.textSecondary)
                            .accessibilityHidden(true)
                        Text(distiller.name)
                            .foregroundColor(.text)
                        Spacer()
                        Button {
                            distillers.removeAll { $0 == distiller }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.textSecondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Remove \(distiller.name)")
                    }
                    .inputBox()
                }

                NavigationLink {
                    DistillerPickerView(
                        selected: distillers,
                        entityRepository: entityRepository
                    ) { distiller in
                        distillers.append(distiller)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.textSecondary)
                            .accessibilityHidden(true)
                        Text("Search distilleries")
                            .foregroundColor(.textMuted)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.textSecondary)
                            .accessibilityHidden(true)
                    }
                    .contentShape(Rectangle())
                    .inputBox()
                }
                .buttonStyle(.plain)

                Text("The distilleries that produced the spirit.")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
    }

    private var datesSection: some View {
        FormSection("Dates") {
            TextInput(
                label: "Distillation year (optional)",
                placeholder: "2024",
                text: $vintageYear,
                leadingSystemImage: "calendar",
                keyboard: .numberPad,
                submitLabel: .next,
                error: yearError(vintageYear),
                onSubmit: { focusReleaseYear = true },
                isFocused: $focusVintageYear
            )

            TextInput(
                label: "Release year (optional)",
                placeholder: "2024",
                text: $releaseYear,
                leadingSystemImage: "calendar",
                keyboard: .numberPad,
                submitLabel: .done,
                error: yearError(releaseYear),
                isFocused: $focusReleaseYear
            )
        }
    }

    private var productionSection: some View {
        FormSection("Production") {
            switchRow(
                "Single cask",
                description: "The label states that this is a single-cask bottling.",
                isOn: $singleCask
            )

            switchRow(
                "Cask strength",
                description: "The label states that this was bottled at cask strength.",
                isOn: $caskStrength
            )
        }
    }

    private func switchRow(_ title: String, description: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .foregroundColor(.text)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
        }
        .tint(.brand)
    }

    // MARK: - Category Picker in InputBox style

    private var categoryPickerRow: some View {
        Menu {
            ForEach(BottleCategory.allCases, id: \.self) { value in
                Button(value.displayName) { category = value }
            }

            if category != nil {
                Divider()
                Button("Not set") { category = nil }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "tag")
                    .foregroundColor(.textSecondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Type (optional)").font(.caption).foregroundColor(.textSecondary)
                    Text(category?.displayName ?? "Not set")
                        .foregroundColor(.text)
                }
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            .inputBox()
        }
    }

    private func createBottle() {
        guard isValid else { return }

        isCreating = true
        let input = draftInput

        Task {
            do {
                let newBottle = try await bottleRepository.createBottle(input)
                onBottleCreated(newBottle)
                dismiss()
            } catch {
                Telemetry.capture(error, feature: "create_bottle", operation: "submit")
                errorMessage = error.localizedDescription
                showingError = true
            }
            isCreating = false
        }
    }
}

// MARK: - Draft and validation

extension ManualBottleEntryView {
    private var isValid: Bool {
        !bottleName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !brandName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            abvError == nil &&
            ageError == nil &&
            yearError(vintageYear) == nil &&
            yearError(releaseYear) == nil
    }

    private var abvValue: Double? {
        let value = abv.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }
        return Double(value.replacingOccurrences(of: ",", with: "."))
    }

    private var ageValue: Int? {
        let value = age.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }
        return Int(value)
    }

    private var abvError: String? {
        let value = abv.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }
        guard let abvValue, (0 ... 100).contains(abvValue) else {
            return "Enter an ABV between 0 and 100."
        }
        return nil
    }

    private var ageError: String? {
        let value = age.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }
        guard let ageValue, (0 ... 100).contains(ageValue) else {
            return "Enter an age between 0 and 100."
        }
        return nil
    }

    private static let yearRange = 1800 ... Calendar.current.component(.year, from: .now)

    private func yearValue(_ text: String) -> Int? {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }
        return Int(value)
    }

    private func yearError(_ text: String) -> String? {
        let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }
        guard let year = yearValue(value), Self.yearRange.contains(year) else {
            return "Enter a year between \(Self.yearRange.lowerBound) and \(Self.yearRange.upperBound)."
        }
        return nil
    }

    private var draftInput: CreateBottleInput {
        let trimmedEdition = edition.trimmingCharacters(in: .whitespacesAndNewlines)
        return CreateBottleInput(
            name: bottleName.trimmingCharacters(in: .whitespacesAndNewlines),
            brandName: brandName.trimmingCharacters(in: .whitespacesAndNewlines),
            category: category,
            statedAge: noAgeStatement ? nil : ageValue,
            noAgeStatement: noAgeStatement,
            abv: abvValue,
            edition: trimmedEdition.isEmpty ? nil : trimmedEdition,
            distillers: distillers,
            singleCask: singleCask,
            caskStrength: caskStrength,
            vintageYear: yearValue(vintageYear),
            releaseYear: yearValue(releaseYear)
        )
    }
}

// MARK: - Existing bottle check

/// Mirrors the web create form: check the catalog for the draft, then review matches before adding.
extension ManualBottleEntryView {
    private var candidateReviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            BottleCreateCandidateReview(
                draft: draftBottle,
                results: reviewResults,
                onUse: useExistingBottle
            )

            Button {
                continueAfterCandidateReview()
            } label: {
                Text(addAfterReview ? "Add as a new bottle" : "None of these")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(.brand)
        }
        .padding(.horizontal)
    }

    /// The draft to check against the catalog, once it has a brand and a name.
    private var candidateInput: CreateBottleInput? {
        let input = draftInput
        return input.name.isEmpty || input.brandName.isEmpty ? nil : input
    }

    private var unreviewedCandidates: [Bottle] {
        candidates.filter { !reviewedCandidateIds.contains($0.id) }
    }

    private var isReviewingCandidates: Bool {
        !reviewResults.isEmpty
    }

    private var addButtonTitle: String {
        let count = unreviewedCandidates.count
        guard count > 0 else { return "Add" }
        return "Review \(count) \(count == 1 ? "bottle" : "bottles")"
    }

    /// The draft as a bottle, so the review shows it with the same identity lines as the matches.
    private var draftBottle: Bottle {
        let input = draftInput
        return Bottle(
            id: "draft",
            name: input.name,
            fullName: "\(input.brandName) \(input.name)",
            brand: Brand(id: "draft-brand", name: input.brandName),
            category: input.category?.rawValue,
            edition: input.edition,
            statedAge: input.statedAge,
            releaseYear: input.releaseYear,
            noAgeStatement: input.noAgeStatement,
            abv: input.abv
        )
    }

    private func checkCandidates(_ input: CreateBottleInput?) async {
        guard let input else {
            candidates = []
            isCheckingCandidates = false
            return
        }

        isCheckingCandidates = true
        do {
            // `.task(id:)` cancels this sleep when the draft changes, which debounces typing.
            try await Task.sleep(for: .milliseconds(300))
            candidates = try await bottleRepository.findCreateCandidates(input)
        } catch {
            // A newer check owns the state now.
            if Task.isCancelled {
                return
            }
            // The check is advisory. On failure the person can still add the bottle.
            Telemetry.capture(error, feature: "create_bottle", operation: "check_candidates")
            candidates = []
        }
        isCheckingCandidates = false
    }

    private func openCandidateReview(addAfterReview: Bool) {
        guard !unreviewedCandidates.isEmpty else { return }
        self.addAfterReview = addAfterReview
        reviewResults = unreviewedCandidates
    }

    private func closeCandidateReview() {
        reviewResults = []
        addAfterReview = false
    }

    private func markCandidateReviewComplete() {
        reviewedCandidateIds.formUnion(reviewResults.map(\.id))
    }

    private func continueAfterCandidateReview() {
        markCandidateReviewComplete()
        let shouldAdd = addAfterReview
        closeCandidateReview()
        if shouldAdd {
            createBottle()
        }
    }

    private func useExistingBottle(_ bottle: Bottle) {
        markCandidateReviewComplete()
        onBottleCreated(bottle)
        dismiss()
    }

    private func addBottle() {
        if unreviewedCandidates.isEmpty {
            createBottle()
        } else {
            openCandidateReview(addAfterReview: true)
        }
    }
}

#Preview {
    ManualBottleEntryView { bottle in
        print("Created bottle: \(bottle.fullName)")
    }
}
