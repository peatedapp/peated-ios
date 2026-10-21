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

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    basicInfoSection
                    madeBySection
                    detailsSection
                    datesSection
                    productionSection
                }
                .padding(.vertical)
            }
            .navigationTitle("Add Bottle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        createBottle()
                    }
                    .fontWeight(.medium)
                    .disabled(!isValid || isCreating)
                }
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

    private func createBottle() {
        guard isValid else { return }

        isCreating = true
        let trimmedName = bottleName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBrand = brandName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEdition = edition.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            do {
                let newBottle = try await bottleRepository.createBottle(CreateBottleInput(
                    name: trimmedName,
                    brandName: trimmedBrand,
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
                ))
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

#Preview {
    ManualBottleEntryView { bottle in
        print("Created bottle: \(bottle.fullName)")
    }
}
