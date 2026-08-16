import PeatedCore
import SwiftUI

struct ManualBottleEntryView: View {
    @Environment(\.dismiss) private var dismiss
    let onBottleCreated: (Bottle) -> Void

    @State private var bottleName = ""
    @State private var brandName = ""
    @State private var category: String = "scotch"
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

    private let categories = [
        ("scotch", "Scotch"),
        ("bourbon", "Bourbon"),
        ("rye", "Rye"),
        ("irish", "Irish"),
        ("japanese", "Japanese"),
        ("single_malt", "Single Malt"),
        ("blended", "Blended"),
        ("other", "Other")
    ]

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
                            ProgressView("Creating bottle...")
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
        FormSection("Basic Information") {
            TextInput(
                label: "Bottle Name",
                placeholder: "Bottle Name",
                text: $bottleName,
                leadingSystemImage: "wineglass",
                isSecure: false,
                keyboard: .default,
                submitLabel: .next,
                autocorrection: true,
                capitalization: .words,
                onSubmit: { focusBrand = true },
                isFocused: $focusName
            )

            TextInput(
                label: "Brand/Distillery",
                placeholder: "Brand/Distillery",
                text: $brandName,
                leadingSystemImage: "building.2",
                keyboard: .default,
                submitLabel: .next,
                autocorrection: true,
                capitalization: .words,
                onSubmit: { focusAbv = true },
                isFocused: $focusBrand
            )

            Text("Enter the bottle name and brand as they appear on the label")
                .font(.caption)
                .foregroundColor(.textSecondary)
                .padding(.top, 4)
        }
    }

    private var detailsSection: some View {
        FormSection("Details") {
            categoryPickerRow
            // ABV
            TextInput(
                label: "ABV",
                placeholder: "ABV %",
                text: $abv,
                leadingSystemImage: "percent",
                unit: "%",
                keyboard: .decimalPad,
                submitLabel: .next,
                onSubmit: { focusAge = true },
                isFocused: $focusAbv
            )

            // Age
            TextInput(
                label: "Age",
                placeholder: "Age (optional)",
                text: $age,
                leadingSystemImage: "clock",
                unit: "years",
                keyboard: .numberPad,
                submitLabel: .done,
                isFocused: $focusAge
            )
        }
    }

    // MARK: - Category Picker in InputBox style

    private var categoryPickerRow: some View {
        Menu {
            ForEach(categories, id: \.0) { value, label in
                Button(label) { category = value }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "tag")
                    .foregroundColor(.textSecondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Style").font(.caption).foregroundColor(.textSecondary)
                    Text(categories.first(where: { $0.0 == category })?.1 ?? "")
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
            !brandName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func createBottle() {
        guard isValid else { return }

        isCreating = true

        // Parse ABV and age
        let abvValue = Double(abv)
        let ageValue = Int(age)

        // Create a temporary bottle object
        // In a real app, this would make an API call to create the bottle
        let trimmedName = bottleName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedBrand = brandName.trimmingCharacters(in: .whitespacesAndNewlines)

        let brand = Brand(
            id: UUID().uuidString,
            name: trimmedBrand
        )

        let newBottle = Bottle(
            id: UUID().uuidString,
            name: trimmedName,
            fullName: "\(trimmedBrand) \(trimmedName)",
            brand: brand,
            category: category,
            caskStrength: false,
            singleCask: false,
            statedAge: ageValue,
            imageUrl: nil,
            abv: abvValue,
            avgRating: nil,
            totalRatings: 0
        )

        // Simulate API delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isCreating = false
            onBottleCreated(newBottle)
            dismiss()
        }
    }
}

#Preview {
    ManualBottleEntryView { bottle in
        print("Created bottle: \(bottle.fullName)")
    }
}
