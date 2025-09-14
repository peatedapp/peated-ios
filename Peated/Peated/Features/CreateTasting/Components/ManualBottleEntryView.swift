import SwiftUI
import PeatedCore

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
  
  @FocusState private var focusedField: Field?
  
  enum Field {
    case name, brand, abv, age
  }
  
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
      Form {
        Section {
          TextField("Bottle Name", text: $bottleName)
            .focused($focusedField, equals: .name)
            .textContentType(.name)
            .submitLabel(.next)
            .onSubmit {
              focusedField = .brand
            }
          
          TextField("Brand/Distillery", text: $brandName)
            .focused($focusedField, equals: .brand)
            .textContentType(.organizationName)
            .submitLabel(.next)
            .onSubmit {
              focusedField = .abv
            }
        } header: {
          Text("Basic Information")
        } footer: {
          Text("Enter the bottle name and brand as they appear on the label")
            .font(.caption)
            .foregroundColor(.textSecondary)
        }
        
        Section {
          Picker("Style", selection: $category) {
            ForEach(categories, id: \.0) { value, label in
              Text(label).tag(value)
            }
          }
          
          HStack {
            TextField("ABV %", text: $abv)
              .focused($focusedField, equals: .abv)
              .keyboardType(.decimalPad)
              .submitLabel(.next)
              .onSubmit {
                focusedField = .age
              }
            
            Text("%")
              .foregroundColor(.textSecondary)
          }
          
          HStack {
            TextField("Age (optional)", text: $age)
              .focused($focusedField, equals: .age)
              .keyboardType(.numberPad)
              .submitLabel(.done)
            
            Text("years")
              .foregroundColor(.textSecondary)
          }
        } header: {
          Text("Details")
        }
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
        Button("OK") { }
      } message: {
        Text(errorMessage)
      }
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
      avgRating: 0,
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
