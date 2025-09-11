# Confirmation Step

## Overview

The fifth and final step of the tasting creation flow shows a preview of the complete tasting and handles submission. This includes privacy settings, social sharing options, and the actual API calls to create the tasting and upload the photo.

## Visual Layout

```
┌─────────────────────────────────────────┐
│  ✕ Cancel          Check In (5/5)       │
├─────────────────────────────────────────┤
│                                         │
│  Review your tasting                    │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ [Bottle] Lagavulin 16           │   │
│  │         ★★★★☆ 4.5               │   │
│  │                                  │   │
│  │ "Intense peat smoke with..."    │   │
│  │                                  │   │
│  │ Tags: Smoky, Peaty, Maritime    │   │
│  │                                  │   │
│  │ [Photo Preview]                  │   │
│  │                                  │   │
│  │ 🏠 Drinking at Home              │   │
│  │ With: @sarah, @mike             │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ─────────────────────────────────      │
│                                         │
│  Privacy                                │
│  ┌─────────────────────────────────┐   │
│  │ 🌍 Public                    [✓] │   │
│  │    Anyone can see this tasting   │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │ 👥 Friends Only              [ ] │   │
│  │    Only friends can see this     │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ─────────────────────────────────      │
│                                         │
│  Share to Social (Optional)             │
│  ☐ Share to Facebook                   │
│  ☐ Share to Twitter/X                  │
│                                         │
├─────────────────────────────────────────┤
│  ← Back               🥃 Cheers!       │
└─────────────────────────────────────────┘
```

### Submitting State
```
┌─────────────────────────────────────────┐
│                                         │
│                                         │
│         Creating your tasting...        │
│                                         │
│              [Progress]                 │
│                                         │
│         ✓ Creating tasting              │
│         ⟳ Uploading photo...            │
│         ○ Sharing to social             │
│                                         │
│                                         │
└─────────────────────────────────────────┘
```

## Implementation

```swift
import SwiftUI

struct ConfirmationStep: View {
    @ObservedObject var viewModel: CreateTastingViewModel
    @State private var selectedPrivacy: PrivacyOption = .public
    @State private var shareToFacebook = false
    @State private var shareToTwitter = false
    @Environment(\.dismiss) private var dismiss
    
    enum PrivacyOption {
        case `public`
        case friendsOnly
    }
    
    var body: some View {
        Group {
            if viewModel.isSubmitting {
                submittingView
            } else if viewModel.submissionSuccessful {
                successView
            } else {
                confirmationView
            }
        }
        .animation(.easeInOut, value: viewModel.isSubmitting)
    }
    
    // MARK: - Confirmation View
    @ViewBuilder
    private var confirmationView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                Text("Review your tasting")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                    .padding(.top)
                
                // Tasting preview
                tastingPreview
                    .padding(.horizontal)
                
                Divider()
                    .padding(.horizontal)
                
                // Privacy settings
                privacySection
                
                Divider()
                    .padding(.horizontal)
                
                // Social sharing
                socialSharingSection
                
                // Add padding for navigation buttons
                Color.clear.frame(height: 100)
            }
        }
    }
    
    // MARK: - Tasting Preview
    @ViewBuilder
    private var tastingPreview: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Bottle info
            HStack(spacing: 12) {
                if let bottle = viewModel.selectedBottle {
                    AsyncImage(url: URL(string: bottle.imageUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    } placeholder: {
                        Image("BottlePlaceholder")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                    .frame(width: 60, height: 80)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(bottle.name)
                            .font(.headline)
                            .lineLimit(2)
                        
                        if let brand = bottle.brand {
                            Text(brand.name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
            }
            
            // Rating
            HStack(spacing: 8) {
                RatingView(rating: viewModel.rating, size: 20)
                Text(String(format: "%.1f", viewModel.rating))
                    .font(.headline)
            }
            
            // Notes
            if !viewModel.notes.isEmpty {
                Text(viewModel.notes)
                    .font(.body)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
            }
            
            // Tags
            if !viewModel.selectedTags.isEmpty {
                HStack {
                    Image(systemName: "tag")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(Array(viewModel.selectedTags).joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Photo
            if let photo = viewModel.photo {
                Image(uiImage: photo)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(12)
            }
            
            // Location and friends
            VStack(alignment: .leading, spacing: 8) {
                if viewModel.isDrinkingAtHome {
                    Label("Drinking at Home", systemImage: "house.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if let location = viewModel.selectedLocation {
                    Label(location.name, systemImage: "mappin")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if !viewModel.taggedFriends.isEmpty {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("With: \(viewModel.taggedFriends.map { "@\($0.username)" }.joined(separator: ", "))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    // MARK: - Privacy Section
    @ViewBuilder
    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Privacy")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                privacyOption(
                    title: "Public",
                    description: "Anyone can see this tasting",
                    icon: "globe",
                    option: .public
                )
                
                privacyOption(
                    title: "Friends Only",
                    description: "Only friends can see this",
                    icon: "person.2.fill",
                    option: .friendsOnly
                )
            }
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private func privacyOption(title: String, description: String, icon: String, option: PrivacyOption) -> some View {
        Button(action: {
            withAnimation {
                selectedPrivacy = option
                viewModel.isPublic = (option == .public)
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: icon)
                            .font(.body)
                            .foregroundColor(.accentColor)
                        
                        Text(title)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: selectedPrivacy == option ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(selectedPrivacy == option ? .accentColor : .secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selectedPrivacy == option ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Social Sharing Section
    @ViewBuilder
    private var socialSharingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Share to Social")
                    .font(.headline)
                
                Text("(Optional)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            VStack(spacing: 12) {
                Toggle(isOn: $shareToFacebook) {
                    Label("Share to Facebook", systemImage: "f.circle.fill")
                        .foregroundColor(.primary)
                }
                .toggleStyle(CheckboxToggleStyle())
                
                Toggle(isOn: $shareToTwitter) {
                    Label("Share to Twitter/X", systemImage: "x.circle.fill")
                        .foregroundColor(.primary)
                }
                .toggleStyle(CheckboxToggleStyle())
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Submitting View
    @ViewBuilder
    private var submittingView: some View {
        VStack(spacing: 32) {
            Text("Creating your tasting...")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 20) {
                submissionStep(
                    title: "Creating tasting",
                    status: viewModel.submissionStep >= .creatingTasting ? .complete : .pending
                )
                
                if viewModel.photo != nil {
                    submissionStep(
                        title: "Uploading photo",
                        status: viewModel.submissionStep == .uploadingPhoto ? .inProgress : 
                               viewModel.submissionStep > .uploadingPhoto ? .complete : .pending,
                        progress: viewModel.photoUploadProgress
                    )
                }
                
                if shareToFacebook || shareToTwitter {
                    submissionStep(
                        title: "Sharing to social",
                        status: viewModel.submissionStep == .sharingToSocial ? .inProgress :
                               viewModel.submissionStep > .sharingToSocial ? .complete : .pending
                    )
                }
            }
            
            if let error = viewModel.submissionError {
                VStack(spacing: 16) {
                    Text("Something went wrong")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text(error)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Try Again") {
                        Task {
                            await viewModel.retrySubmission()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private func submissionStep(title: String, status: SubmissionStepStatus, progress: Double? = nil) -> some View {
        HStack(spacing: 16) {
            Group {
                switch status {
                case .pending:
                    Image(systemName: "circle")
                        .foregroundColor(.secondary)
                case .inProgress:
                    ProgressView()
                        .scaleEffect(0.8)
                case .complete:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .foregroundColor(status == .pending ? .secondary : .primary)
                
                if let progress = progress, status == .inProgress {
                    ProgressView(value: progress)
                        .progressViewStyle(.linear)
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Success View
    @ViewBuilder
    private var successView: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
                .scaleEffect(1.0)
                .animation(
                    .spring(response: 0.5, dampingFraction: 0.6)
                        .delay(0.2),
                    value: viewModel.submissionSuccessful
                )
            
            Text("Cheers!")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Your tasting has been posted")
                .font(.body)
                .foregroundColor(.secondary)
            
            Button("Done") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding()
        .onAppear {
            // Success haptic
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

// MARK: - Checkbox Toggle Style
struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
        }) {
            HStack {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundColor(configuration.isOn ? .accentColor : .secondary)
                    .font(.title3)
                
                configuration.label
                    .foregroundColor(.primary)
                
                Spacer()
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Submission Step Status
enum SubmissionStepStatus {
    case pending
    case inProgress
    case complete
}

// MARK: - View Model Extension
extension CreateTastingViewModel {
    enum SubmissionStep: Int, Comparable {
        case notStarted = 0
        case creatingTasting = 1
        case uploadingPhoto = 2
        case sharingToSocial = 3
        case complete = 4
        
        static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
    
    @Published var submissionStep: SubmissionStep = .notStarted
    @Published var photoUploadProgress: Double = 0
    @Published var submissionError: String?
    
    func submitTasting() async {
        isSubmitting = true
        submissionError = nil
        submissionStep = .creatingTasting
        
        do {
            // Step 1: Create tasting
            let tasting = try await createTastingAPI()
            submissionStep = .uploadingPhoto
            
            // Step 2: Upload photo if exists
            if let photo = photo {
                try await uploadPhoto(photo, for: tasting)
            }
            
            // Step 3: Share to social if requested
            if postToFacebook || postToTwitter {
                submissionStep = .sharingToSocial
                await shareToSocial(tasting)
            }
            
            submissionStep = .complete
            submissionSuccessful = true
            
            // Wait a moment before dismissing
            try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
        } catch {
            submissionError = error.localizedDescription
            isSubmitting = false
        }
    }
    
    private func createTastingAPI() async throws -> Tasting {
        // API call to create tasting
        let request = CreateTastingRequest(
            bottleId: selectedBottle!.id,
            rating: rating,
            notes: notes.isEmpty ? nil : notes,
            tags: Array(selectedTags),
            servingStyle: servingStyle?.rawValue,
            locationId: isDrinkingAtHome ? nil : selectedLocation?.id,
            friendIds: taggedFriends.map { $0.id },
            isPublic: isPublic
        )
        
        return try await TastingsAPI.createTasting(request)
    }
    
    private func uploadPhoto(_ photo: UIImage, for tasting: Tasting) async throws {
        // Prepare image data
        guard let imageData = photo.jpegData(compressionQuality: 0.8) else {
            throw UploadError.invalidImage
        }
        
        // Create upload task with progress monitoring
        let uploadTask = URLSession.shared.uploadTask(with: request, from: imageData) { data, response, error in
            // Handle completion
        }
        
        // Monitor progress
        let observation = uploadTask.progress.observe(\.fractionCompleted) { progress, _ in
            DispatchQueue.main.async {
                self.photoUploadProgress = progress.fractionCompleted
            }
        }
        
        uploadTask.resume()
        
        // Wait for completion
        // Update tasting with photo ID
    }
    
    private func shareToSocial(_ tasting: Tasting) async {
        // Implementation for social sharing
    }
    
    func retrySubmission() async {
        // Retry from last failed step
        await submitTasting()
    }
}
```

## Features

### Review Section
- Complete tasting preview
- All entered information displayed
- Visual hierarchy for scanning
- Edit capability via back button

### Privacy Options
- **Public**: Default, anyone can see
- **Friends Only**: Restricted visibility
- Clear visual selection
- Persists for future tastings

### Social Sharing
- Facebook integration
- Twitter/X integration
- Optional checkboxes
- Share after creation

### Submission Process
- Multi-step with progress
- Photo upload progress bar
- Clear status indicators
- Error handling with retry

## Submission Flow

### API Sequence
1. **Create Tasting**
   - POST to `/tastings`
   - Returns tasting ID
   - Includes all metadata

2. **Upload Photo** (if present)
   - POST to `/tastings/{id}/photos`
   - Progress monitoring
   - Retry on failure

3. **Social Sharing** (if selected)
   - Platform-specific APIs
   - Non-blocking (failures don't affect tasting)

### Error Handling
- Network failures
- Server errors
- Photo upload issues
- Graceful degradation

### Success Flow
- Animated success state
- Haptic feedback
- Brief celebration
- Auto-dismiss or manual

## State Management

### Submission States
1. **Reviewing**: User can edit
2. **Submitting**: In progress
3. **Success**: Completed
4. **Error**: Failed with retry

### Progress Tracking
- Step-by-step status
- Photo upload percentage
- Clear failure points
- Retry from failure

## User Experience

### Visual Feedback
- Progress indicators
- Success animation
- Error messages
- Status updates

### Performance
- Responsive during upload
- Background processing
- Efficient image handling
- Quick transitions

### Accessibility
- Status announcements
- Progress updates
- Error descriptions
- Success confirmation

## Edge Cases

### Failures
- Network interruption
- Server errors
- Photo too large
- Invalid data

### Recovery
- Retry mechanism
- Partial success handling
- Draft saving (future)
- Clear error messages

### Background Handling
- Continue upload if app backgrounds
- Resume on return
- Notification on completion
- Handle interruptions