import SwiftUI
import PeatedCore

struct CreateTastingFlow: View {
    @StateObject private var viewModel = CreateTastingViewModel()
    @State private var currentStep = 2  // DEBUG: Skip to rating step
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
                ProgressBar(currentStep: currentStep, totalSteps: 6)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Step content
                TabView(selection: $currentStep) {
                    BottleSelectionStep(viewModel: viewModel) {
                        // Automatically advance to step 2 when bottle is selected
                        withAnimation {
                            currentStep = 2
                        }
                    }
                    .tag(1)
                    
                    RatingServingStep(viewModel: viewModel)
                        .tag(2)
                    
                    NotesStep(viewModel: viewModel)
                        .tag(3)
                    
                    LocationStep(viewModel: viewModel)
                        .tag(4)
                    
                    PhotosStep(viewModel: viewModel)
                        .tag(5)
                    
                    ConfirmationStep(viewModel: viewModel)
                        .tag(6)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentStep)
                .ignoresSafeArea(.keyboard)
                
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
            .navigationTitle("Add Tasting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showCancelConfirmation()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Text("\(currentStep)/6")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .interactiveDismissDisabled(viewModel.hasUnsavedChanges)
            .alert("Discard Tasting?", isPresented: $viewModel.showingCancelAlert) {
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
            
            if currentStep < 6 {
                Button(action: nextStep) {
                    HStack {
                        Text("Continue")
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14))
                    }
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.black)  // Changed from .white to .black
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
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))  // Changed from .white to .black
                        } else {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Cheers!")
                            }
                        }
                    }
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)  // Changed from .white to .black
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
            return true // Rating is optional
        case 3:
            return true // Notes and flavors are optional
        case 4:
            return true // Location is optional
        case 5:
            return true // Photos are optional
        case 6:
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
                // TODO: Show success toast
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