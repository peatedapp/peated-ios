import PeatedCore
import SwiftUI

struct ManualBottleEntryView: View {
    @Environment(\.dismiss) private var dismiss
    let onBottleCreated: (Bottle) -> Void
    private let bottleRepository: any BottleRepositoryProtocol

    @State private var bottleName = ""
    @State private var brandName = ""
    @State private var category: BottleCategory?
    @State private var abv = ""
    @State private var age = ""
    @State private var isCreating = false
    @State private var showingError = false
    @State private var errorMessage = ""

    // Local focus bindings for inputs
    @FocusState private var focusName: Bool
    @FocusState private var focusBrand: Bool
    @FocusState private var focusAbv: Bool
    @FocusState private var focusAge: Bool

    init(
        initialInput: CreateBottleInput? = nil,
        bottleRepository: any BottleRepositoryProtocol = BottleRepository(),
        onBottleCreated: @escaping (Bottle) -> Void
    ) {
        self.bottleRepository = bottleRepository
        self.onBottleCreated = onBottleCreated
        _bottleName = State(initialValue: initialInput?.name ?? "")
        _brandName = State(initialValue: initialInput?.brandName ?? "")
        _category = State(initialValue: initialInput?.category)
        _abv = State(initialValue: initialInput?.abv.map { String($0) } ?? "")
        _age = State(initialValue: initialInput?.statedAge.map { String($0) } ?? "")
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    basicInfoSection
                    detailsSection
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
                onSubmit: { focusAge = true },
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
                error: ageError,
                onSubmit: { focusAbv = true },
                isFocused: $focusAge
            )

            TextInput(
                label: "Alcohol (optional)",
                placeholder: "40.5",
                text: $abv,
                leadingSystemImage: "percent",
                unit: "% ABV",
                keyboard: .decimalPad,
                submitLabel: .done,
                error: abvError,
                isFocused: $focusAbv
            )
        }
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
            ageError == nil
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

    private func createBottle() {
        guard isValid else { return }

        isCreating = true
        let trimmedName = bottleName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBrand = brandName.trimmingCharacters(in: .whitespacesAndNewlines)

        Task {
            do {
                let newBottle = try await bottleRepository.createBottle(CreateBottleInput(
                    name: trimmedName,
                    brandName: trimmedBrand,
                    category: category,
                    statedAge: ageValue,
                    abv: abvValue
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
