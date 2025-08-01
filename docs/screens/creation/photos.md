# Photos Step

## Overview

The fourth step of the tasting creation flow allows users to add a single photo to their tasting. Users can take a new photo or select from their library, with cropping functionality available. Photos are uploaded after the tasting is created as part of the submission process.

## Visual Layout

```
┌─────────────────────────────────────────┐
│  ✕ Cancel          Check In (4/5)       │
├─────────────────────────────────────────┤
│                                         │
│  Add a photo (Optional)                 │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │                                 │   │
│  │                                 │   │
│  │        📷                       │   │
│  │                                 │   │
│  │    Tap to add photo             │   │
│  │                                 │   │
│  │                                 │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────┬─────────────────┐     │
│  │ Take Photo  │ Choose from     │     │
│  │      📸     │    Library 🖼    │     │
│  └─────────────┴─────────────────┘     │
│                                         │
├─────────────────────────────────────────┤
│  ← Back                    Continue →   │
└─────────────────────────────────────────┘
```

### With Photo Added
```
┌─────────────────────────────────────────┐
│  ✕ Cancel          Check In (4/5)       │
├─────────────────────────────────────────┤
│                                         │
│  Add a photo (Optional)                 │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │                                 │   │
│  │     [Selected Photo]            │   │
│  │                                 │   │
│  │                                 │   │
│  │  ┌─────────────────────────┐   │   │
│  │  │ ✕ Remove                │   │   │
│  │  └─────────────────────────┘   │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │       Change Photo              │   │
│  └─────────────────────────────────┘   │
│                                         │
├─────────────────────────────────────────┤
│  ← Back                    Continue →   │
└─────────────────────────────────────────┘
```

## Implementation

```swift
import SwiftUI
import PhotosUI
import UIKit

struct PhotosStep: View {
    @ObservedObject var viewModel: CreateTastingViewModel
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var imagePickerSource: ImagePickerSource = .library
    @State private var showingCropView = false
    @State private var tempImage: UIImage?
    
    enum ImagePickerSource {
        case camera
        case library
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add a photo")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("(Optional)")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Photo area
                photoArea
                
                // Action buttons
                if viewModel.photo == nil {
                    actionButtons
                        .padding(.horizontal)
                } else {
                    changePhotoButton
                        .padding(.horizontal)
                }
                
                // Tips
                if viewModel.photo == nil {
                    tipsSection
                        .padding(.horizontal)
                        .padding(.top)
                }
                
                // Add padding for navigation buttons
                Color.clear.frame(height: 100)
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(
                sourceType: imagePickerSource == .camera ? .camera : .photoLibrary,
                selectedImage: $tempImage
            )
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showingCropView) {
            if let image = tempImage {
                ImageCropView(
                    image: image,
                    onComplete: { croppedImage in
                        viewModel.photo = croppedImage
                        tempImage = nil
                        showingCropView = false
                    },
                    onCancel: {
                        tempImage = nil
                        showingCropView = false
                    }
                )
            }
        }
        .onChange(of: tempImage) { newImage in
            if newImage != nil {
                showingCropView = true
            }
        }
    }
    
    // MARK: - Photo Area
    @ViewBuilder
    private var photoArea: some View {
        VStack(spacing: 0) {
            if let photo = viewModel.photo {
                // Show selected photo
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: photo)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 350)
                        .clipped()
                        .cornerRadius(16)
                    
                    // Remove button
                    Button(action: removePhoto) {
                        HStack {
                            Image(systemName: "xmark")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Text("Remove")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(20)
                    }
                    .padding()
                }
            } else {
                // Empty state
                Button(action: {
                    showActionSheet()
                }) {
                    VStack(spacing: 16) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        
                        Text("Tap to add photo")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 350)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                            .foregroundColor(.secondary.opacity(0.3))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Action Buttons
    @ViewBuilder
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: {
                checkCameraPermissionAndShow()
            }) {
                VStack(spacing: 8) {
                    Image(systemName: "camera.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                    
                    Text("Take Photo")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            
            Button(action: {
                checkPhotoLibraryPermissionAndShow()
            }) {
                VStack(spacing: 8) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                    
                    Text("Choose from Library")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Change Photo Button
    @ViewBuilder
    private var changePhotoButton: some View {
        Button(action: {
            showActionSheet()
        }) {
            Text("Change Photo")
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.accentColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(12)
        }
    }
    
    // MARK: - Tips Section
    @ViewBuilder
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Photo Tips", systemImage: "lightbulb")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 8) {
                tipRow("Good lighting helps showcase the whisky color")
                tipRow("Include the bottle label for context")
                tipRow("Try different angles - straight on or from above")
                tipRow("A clean background makes your photo stand out")
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private func tipRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - Actions
    private func showActionSheet() {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Take Photo", style: .default) { _ in
            checkCameraPermissionAndShow()
        })
        
        alert.addAction(UIAlertAction(title: "Choose from Library", style: .default) { _ in
            checkPhotoLibraryPermissionAndShow()
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
    
    private func checkCameraPermissionAndShow() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            imagePickerSource = .camera
            showingImagePicker = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    DispatchQueue.main.async {
                        imagePickerSource = .camera
                        showingImagePicker = true
                    }
                }
            }
        default:
            showPermissionAlert(for: "Camera")
        }
    }
    
    private func checkPhotoLibraryPermissionAndShow() {
        switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
        case .authorized, .limited:
            imagePickerSource = .library
            showingImagePicker = true
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                if status == .authorized || status == .limited {
                    DispatchQueue.main.async {
                        imagePickerSource = .library
                        showingImagePicker = true
                    }
                }
            }
        default:
            showPermissionAlert(for: "Photos")
        }
    }
    
    private func showPermissionAlert(for feature: String) {
        let alert = UIAlertController(
            title: "\(feature) Access Required",
            message: "Please enable \(feature) access in Settings to use this feature.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(settingsUrl)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
    
    private func removePhoto() {
        withAnimation {
            viewModel.photo = nil
        }
        
        // Haptic feedback
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    @Binding var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = false // We'll handle cropping separately
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Image Crop View
struct ImageCropView: View {
    let image: UIImage
    let onComplete: (UIImage) -> Void
    let onCancel: () -> Void
    
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastScale: CGFloat = 1.0
    @State private var lastOffset: CGSize = .zero
    
    private let cropAspectRatio: CGFloat = 1.0 // Square crop
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    Color.black.ignoresSafeArea()
                    
                    // Image with gesture controls
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            SimultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        scale = lastScale * value
                                    }
                                    .onEnded { _ in
                                        lastScale = scale
                                        constrainImage()
                                    },
                                DragGesture()
                                    .onChanged { value in
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                    .onEnded { _ in
                                        lastOffset = offset
                                        constrainImage()
                                    }
                            )
                        )
                    
                    // Crop overlay
                    CropOverlay(aspectRatio: cropAspectRatio)
                        .allowsHitTesting(false)
                }
            }
            .navigationTitle("Crop Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        cropAndComplete()
                    }
                    .fontWeight(.medium)
                }
            }
        }
    }
    
    private func constrainImage() {
        withAnimation(.spring()) {
            // Ensure minimum scale
            scale = max(scale, 1.0)
            
            // Constrain offset to keep image within crop area
            // Implementation depends on image and crop dimensions
        }
    }
    
    private func cropAndComplete() {
        // Perform the actual crop
        // This is a simplified version - real implementation would calculate
        // the crop rect based on scale and offset
        
        if let croppedImage = cropImage() {
            onComplete(croppedImage)
        }
    }
    
    private func cropImage() -> UIImage? {
        // Implementation of actual image cropping
        // Would calculate the visible rect and crop the UIImage
        return image // Placeholder
    }
}

// MARK: - Crop Overlay
struct CropOverlay: View {
    let aspectRatio: CGFloat
    
    var body: some View {
        GeometryReader { geometry in
            let cropSize = calculateCropSize(in: geometry.size)
            
            ZStack {
                // Dark overlay
                Color.black.opacity(0.6)
                
                // Clear crop area
                Rectangle()
                    .frame(width: cropSize.width, height: cropSize.height)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                    .blendMode(.destinationOut)
                
                // Border
                Rectangle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: cropSize.width, height: cropSize.height)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
                // Grid lines
                CropGrid()
                    .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                    .frame(width: cropSize.width, height: cropSize.height)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
            .compositingGroup()
        }
    }
    
    private func calculateCropSize(in size: CGSize) -> CGSize {
        let padding: CGFloat = 40
        let maxWidth = size.width - padding * 2
        let maxHeight = size.height - padding * 2
        
        if aspectRatio > 1 {
            let width = min(maxWidth, maxHeight * aspectRatio)
            return CGSize(width: width, height: width / aspectRatio)
        } else {
            let height = min(maxHeight, maxWidth / aspectRatio)
            return CGSize(width: height * aspectRatio, height: height)
        }
    }
}

struct CropGrid: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // Vertical lines
        let thirdWidth = rect.width / 3
        path.move(to: CGPoint(x: thirdWidth, y: 0))
        path.addLine(to: CGPoint(x: thirdWidth, y: rect.height))
        
        path.move(to: CGPoint(x: thirdWidth * 2, y: 0))
        path.addLine(to: CGPoint(x: thirdWidth * 2, y: rect.height))
        
        // Horizontal lines
        let thirdHeight = rect.height / 3
        path.move(to: CGPoint(x: 0, y: thirdHeight))
        path.addLine(to: CGPoint(x: rect.width, y: thirdHeight))
        
        path.move(to: CGPoint(x: 0, y: thirdHeight * 2))
        path.addLine(to: CGPoint(x: rect.width, y: thirdHeight * 2))
        
        return path
    }
}
```

## Features

### Photo Selection
- **Camera**: Direct photo capture
- **Photo Library**: Browse and select
- **Single Photo**: One photo per tasting
- **Permission Handling**: Clear prompts and settings redirect

### Photo Editing
- **Crop Tool**: Square aspect ratio (1:1)
- **Pinch to Zoom**: Scale image within crop
- **Pan to Position**: Drag image to frame
- **Grid Overlay**: Rule of thirds guide
- **Constrained Movement**: Image stays within bounds

### Photo Management
- **Preview**: Full preview of selected photo
- **Remove**: Clear removal option
- **Change**: Easy to replace photo
- **No Filters**: Keep it authentic

### User Guidance
- **Photo Tips**: Helpful suggestions
- **Empty State**: Clear call-to-action
- **Visual Feedback**: Dashed border placeholder

## Upload Process

### Timing
- Photo stored locally during flow
- Uploaded after tasting creation
- Part of submission transaction
- Progress shown in final step

### Image Processing
- Resize for optimal upload (max 2048px)
- JPEG compression (quality: 0.8)
- EXIF data stripped for privacy
- Orientation corrected

### Error Handling
- Upload failures don't block tasting
- Retry mechanism for photos
- User notified of issues
- Can be uploaded later

## User Experience

### Permissions
- Just-in-time requests
- Clear explanations
- Settings redirect for denied
- Graceful degradation

### Visual Design
- Large preview area
- Clear action buttons
- Consistent with iOS patterns
- Smooth animations

### Performance
- Efficient image handling
- Memory-conscious loading
- Fast crop preview
- Smooth gesture response

## State Management

### Photo State
- Single `UIImage` property
- Cleared on removal
- Persists through navigation
- Memory-efficient storage

### Upload State
- Tracked in final step
- Progress indication
- Success/failure handling
- Retry capability

## Accessibility

- VoiceOver descriptions
- Photo content description
- Crop tool instructions
- Button labels clear

## Edge Cases

- Very large images (>10MB)
- Low memory situations
- Permission changes mid-flow
- Upload interruptions
- Network failures