# Tasting Creation Flow Overview

## Overview

The tasting creation flow is a 5-step process that guides users through adding a new whisky tasting. It's designed to be quick and intuitive while capturing all essential information. The flow can be initiated from multiple entry points and supports both quick and detailed check-ins.

## Flow Structure

```
┌─────────────────────┐
│  1. Select Bottle   │
│  Search or Scan     │
└──────────┬──────────┘
           │
┌──────────▼──────────┐
│  2. Rate & Notes    │
│  Rating + Tasting   │
└──────────┬──────────┘
           │
┌──────────▼──────────┐
│  3. Location        │
│  Where drinking     │
└──────────┬──────────┘
           │
┌──────────▼──────────┐
│  4. Add Photos      │
│  Camera or Library  │
└──────────┬──────────┘
           │
┌──────────▼──────────┐
│  5. Confirm & Post  │
│  Review & Share     │
└─────────────────────┘
```

## Navigation Pattern

```
┌─────────────────────────────────────────┐
│  ✕ Cancel              Check In    (3/5)│
├─────────────────────────────────────────┤
│                                         │
│         [Step Content]                  │
│                                         │
├─────────────────────────────────────────┤
│  ← Back              Continue →         │
└─────────────────────────────────────────┘
```

## Implementation

```swift
import SwiftUI

struct CreateTastingFlow: View {
    @StateObject private var viewModel = CreateTastingViewModel()
    @State private var currentStep = 1
    @Environment(\.dismiss) private var dismiss
    
    // Pre-filled data (optional)
    let preselectedBottle: Bottle?
    let preselectedLocation: Location?
    
    init(preselectedBottle: Bottle? = nil, preselectedLocation: Location? = nil) {
        self.preselectedBottle = preselectedBottle
        self.preselectedLocation = preselectedLocation
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress indicator
                ProgressBar(currentStep: currentStep, totalSteps: 5)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Step content
                TabView(selection: $currentStep) {
                    BottleSelectionStep(viewModel: viewModel)
                        .tag(1)
                    
                    RatingNotesStep(viewModel: viewModel)
                        .tag(2)
                    
                    LocationStep(viewModel: viewModel)
                        .tag(3)
                    
                    PhotosStep(viewModel: viewModel)
                        .tag(4)
                    
                    ConfirmationStep(viewModel: viewModel)
                        .tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)
                
                // Navigation buttons
                navigationButtons
                    .padding()
                    .background(Color(.systemBackground))
                    .overlay(
                        Rectangle()
                            .fill(Color(.separator))
                            .frame(height: 0.5),
                        alignment: .top
                    )
            }
            .navigationTitle("Check In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showCancelConfirmation()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Text("\(currentStep)/5")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .interactiveDismissDisabled(viewModel.hasUnsavedChanges)
            .alert("Discard Check-In?", isPresented: $viewModel.showingCancelAlert) {
                Button("Discard", role: .destructive) {
                    dismiss()
                }
                Button("Keep Editing", role: .cancel) { }
            } message: {
                Text("You'll lose any information you've entered.")
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
        .onAppear {
            setupPreselectedData()
        }
    }
    
    // MARK: - Navigation Buttons
    @ViewBuilder
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if currentStep > 1 {
                Button(action: previousStep) {
                    HStack {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14))
                        Text("Back")
                    }
                    .font(.body)
                    .foregroundColor(.accentColor)
                }
            }
            
            Spacer()
            
            if currentStep < 5 {
                Button(action: nextStep) {
                    HStack {
                        Text("Continue")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                    }
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Color.accentColor
                            .opacity(canProceed ? 1.0 : 0.5)
                    )
                    .cornerRadius(20)
                }
                .disabled(!canProceed)
            } else {
                Button(action: submitTasting) {
                    Group {
                        if viewModel.isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Cheers!")
                            }
                        }
                    }
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(minWidth: 120)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .cornerRadius(25)
                }
                .disabled(viewModel.isSubmitting)
            }
        }
    }
    
    // MARK: - Computed Properties
    private var canProceed: Bool {
        switch currentStep {
        case 1:
            return viewModel.selectedBottle != nil
        case 2:
            return viewModel.rating > 0
        case 3:
            return true // Location is optional
        case 4:
            return true // Photos are optional
        case 5:
            return !viewModel.isSubmitting
        default:
            return false
        }
    }
    
    // MARK: - Actions
    private func previousStep() {
        withAnimation {
            currentStep -= 1
        }
    }
    
    private func nextStep() {
        withAnimation {
            currentStep += 1
        }
    }
    
    private func submitTasting() {
        Task {
            await viewModel.submitTasting()
            if viewModel.submissionSuccessful {
                dismiss()
                // Show success toast
            }
        }
    }
    
    private func showCancelConfirmation() {
        if viewModel.hasUnsavedChanges {
            viewModel.showingCancelAlert = true
        } else {
            dismiss()
        }
    }
    
    private func setupPreselectedData() {
        if let bottle = preselectedBottle {
            viewModel.selectedBottle = bottle
            // Skip to step 2 if bottle is preselected
            currentStep = 2
        }
        
        if let location = preselectedLocation {
            viewModel.selectedLocation = location
        }
    }
}

// MARK: - Progress Bar
struct ProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(.systemGray5))
                    .frame(height: 4)
                
                // Progress
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.accentColor)
                    .frame(
                        width: geometry.size.width * (CGFloat(currentStep) / CGFloat(totalSteps)),
                        height: 4
                    )
                    .animation(.easeInOut(duration: 0.3), value: currentStep)
            }
        }
        .frame(height: 4)
    }
}

// MARK: - View Model
@MainActor
class CreateTastingViewModel: ObservableObject {
    // Step 1: Bottle
    @Published var selectedBottle: Bottle?
    @Published var bottleSearchText = ""
    
    // Step 2: Rating & Notes
    @Published var rating: Double = 0
    @Published var notes = ""
    @Published var selectedTags: Set<String> = []
    @Published var servingStyle: ServingStyle?
    
    // Step 3: Location
    @Published var selectedLocation: Location?
    @Published var isDrinkingAtHome = false
    @Published var taggedFriends: [User] = []
    
    // Step 4: Photos
    @Published var photos: [UIImage] = []
    @Published var uploadedPhotoIds: [String] = []
    
    // Step 5: Confirmation
    @Published var isPublic = true
    @Published var postToFacebook = false
    @Published var postToTwitter = false
    
    // State
    @Published var isSubmitting = false
    @Published var submissionSuccessful = false
    @Published var showingError = false
    @Published var errorMessage = ""
    @Published var showingCancelAlert = false
    
    var hasUnsavedChanges: Bool {
        selectedBottle != nil || 
        rating > 0 || 
        !notes.isEmpty || 
        !photos.isEmpty
    }
    
    private let repository: TastingRepository
    
    init(repository: TastingRepository = TastingRepositoryImpl()) {
        self.repository = repository
    }
    
    func submitTasting() async {
        isSubmitting = true
        showingError = false
        
        do {
            // Upload photos first
            if !photos.isEmpty {
                uploadedPhotoIds = try await uploadPhotos()
            }
            
            // Create tasting
            let input = CreateTastingInput(
                bottle: selectedBottle!,
                rating: rating,
                notes: notes.isEmpty ? nil : notes,
                tags: Array(selectedTags),
                servingStyle: servingStyle,
                location: isDrinkingAtHome ? nil : selectedLocation,
                taggedFriends: taggedFriends,
                imageIds: uploadedPhotoIds,
                isPublic: isPublic
            )
            
            let tasting = try await repository.createTasting(input)
            
            // Post to social media if requested
            if postToFacebook || postToTwitter {
                await postToSocialMedia(tasting)
            }
            
            submissionSuccessful = true
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
        
        isSubmitting = false
    }
    
    private func uploadPhotos() async throws -> [String] {
        // Implementation for photo upload
        []
    }
    
    private func postToSocialMedia(_ tasting: Tasting) async {
        // Implementation for social sharing
    }
}
```

## Entry Points

### Primary Entry
- Floating "+" button on main tabs
- Available from Feed, Search, Library, Profile tabs

### Contextual Entry
- "Check In" button on bottle detail
- Quick action from library
- Push notification response
- Deep link with bottle ID

### Pre-filled Scenarios
1. **From Bottle Detail**: Bottle pre-selected, start at step 2
2. **From Location**: Location pre-selected
3. **From Barcode Scan**: Bottle found and selected
4. **From Deep Link**: Various fields pre-populated

## Navigation Rules

### Forward Navigation
- "Continue" enabled when required fields complete
- Skip to next step on field completion (optional)
- Smooth animation between steps

### Backward Navigation
- "Back" button always available (except step 1)
- Preserve all entered data
- No validation on backward movement

### Cancellation
- Confirmation required if data entered
- "Discard Check-In?" alert
- Data cleared on confirmation

## Data Validation

### Required Fields
- **Step 1**: Bottle selection
- **Step 2**: Rating (minimum)
- **Step 5**: Confirmation

### Optional Fields
- Tasting notes
- Flavor tags
- Serving style
- Location
- Tagged friends
- Photos
- Privacy settings

## State Management

### Local State
- All input preserved during flow
- Draft saved on app backgrounding
- Restore on app return

### Submission
- Show loading state
- Disable all inputs
- Handle errors gracefully
- Success animation

## Accessibility

- VoiceOver support for all steps
- Keyboard navigation
- Clear focus management
- Progress announcements

## Performance

- Lazy load step content
- Efficient photo handling
- Debounced searches
- Minimal re-renders

## Error Handling

### Network Errors
- Retry mechanism
- Offline queue (future)
- Clear error messages

### Validation Errors
- Inline field validation
- Clear error states
- Helpful suggestions

## Analytics Events

- `tasting_flow_started` (entry_point)
- `tasting_step_completed` (step_number)
- `tasting_flow_cancelled` (step_number)
- `tasting_submitted` (with_photos, with_location)
- `tasting_shared` (platform)