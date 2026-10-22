import PeatedCore
import SwiftUI

struct CreateTastingFlow: View {
    @StateObject private var viewModel = CreateTastingViewModel()
    @State private var currentStep = 1 // Start at bottle selection
    @Environment(\.dismiss) private var dismiss

    // Pre-filled data (optional)
    let preselectedBottle: Bottle?
    let preselectedLocation: Location?
    let onSuccess: (() -> Void)?

    init(preselectedBottle: Bottle? = nil, preselectedLocation: Location? = nil, onSuccess: (() -> Void)? = nil) {
        self.preselectedBottle = preselectedBottle
        self.preselectedLocation = preselectedLocation
        self.onSuccess = onSuccess
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

                navigationButtons
            }
            .navigationTitle("Add Tasting")
            .navigationBarTitleDisplayMode(.inline)
            .navigationChrome()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showCancelConfirmation()
                    }
                    .accessibilityIdentifier(AccessibilityID.CreateTasting.cancel)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    StepCountLabel(current: currentStep, total: 6)
                }
            }
            .interactiveDismissDisabled(viewModel.hasUnsavedChanges)
            .alert("Discard Tasting?", isPresented: $viewModel.showingCancelAlert) {
                Button("Discard", role: .destructive) {
                    dismiss()
                }
                Button("Keep Editing", role: .cancel) {}
            } message: {
                Text("You'll lose any information you've entered.")
            }
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK") {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
        .screenBackground()
        .onAppear {
            setupPreselectedData()
        }
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        StepNavigationBar(onBack: backAction, backIdentifier: AccessibilityID.CreateTasting.back) {
            if currentStep < 6 {
                StepContinueButton(title: "Continue", isEnabled: canProceed, action: nextStep)
                    .accessibilityIdentifier(AccessibilityID.CreateTasting.continueButton)
            } else {
                Button(action: submitTasting) {
                    Group {
                        if viewModel.isSubmitting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .onStatus))
                        } else {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Cheers!")
                            }
                        }
                    }
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.onBrand)
                    .frame(minWidth: 120)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.brand)
                    .cornerRadius(25)
                }
                .disabled(viewModel.isSubmitting)
                .accessibilityIdentifier(AccessibilityID.CreateTasting.submit)
            }
        }
    }

    // MARK: - Computed Properties

    private var backAction: (() -> Void)? {
        guard currentStep > 1 else { return nil }
        return previousStep
    }

    private var canProceed: Bool {
        switch currentStep {
        case 1:
            viewModel.selectedBottle != nil
        case 2:
            true // Rating is optional
        case 3:
            true // Notes and comments are optional
        case 4:
            true // Location is optional
        case 5:
            true // Photos are optional
        case 6:
            !viewModel.isSubmitting
        default:
            false
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
                // Call the success callback to show toast in parent view
                onSuccess?()
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
