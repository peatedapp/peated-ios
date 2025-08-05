import SwiftUI
import PhotosUI

#if canImport(UIKit)
import UIKit
#endif

struct PhotosStep: View {
    @ObservedObject var viewModel: CreateTastingViewModel
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showingCamera = false
    @State private var showingImagePicker = false
    @State private var sourceType: UIImagePickerController.SourceType = .camera
    
    private let maxPhotos = 4
    
    var body: some View {
        SwiftUI.ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Add photos")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Share the moment with photos (optional)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top)
                
                VStack(spacing: 20) {
                    // Photo Grid
                    if !viewModel.photos.isEmpty {
                        PhotoGrid(
                            photos: viewModel.photos,
                            onRemove: { index in
                                withAnimation(.spring(response: 0.3)) {
                                    _ = viewModel.photos.remove(at: index)
                                }
                            }
                        )
                    }
                    
                    // Add Photo Buttons
                    if viewModel.photos.count < maxPhotos {
                        VStack(spacing: 16) {
                            // Camera Button
                            AddPhotoButton(
                                icon: "camera.fill",
                                title: "Take Photo",
                                subtitle: "Capture the moment",
                                onTap: {
                                    sourceType = .camera
                                    showingImagePicker = true
                                }
                            )
                            
                            // Photo Library Button
                            PhotosPicker(
                                selection: $selectedPhotos,
                                maxSelectionCount: maxPhotos - viewModel.photos.count,
                                matching: .images
                            ) {
                                AddPhotoButtonContent(
                                    icon: "photo.on.rectangle",
                                    title: "Choose from Library",
                                    subtitle: "Select existing photos"
                                )
                            }
                            .onChange(of: selectedPhotos) { _, newPhotos in
                                Task {
                                    await loadSelectedPhotos(newPhotos)
                                }
                            }
                        }
                    }
                    
                    // Photo Count Info
                    if viewModel.photos.count > 0 {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.secondary)
                            
                            Text("\(viewModel.photos.count) of \(maxPhotos) photos added")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                    
                    // Tips Section
                    if viewModel.photos.isEmpty {
                        PhotoTipsView()
                    }
                }
                .padding(.horizontal)
            }
            .padding(.bottom, 100) // Space for navigation buttons
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(
                sourceType: sourceType,
                onImageSelected: { image in
                    withAnimation(.spring(response: 0.3)) {
                        viewModel.photos.append(image)
                    }
                }
            )
        }
    }
    
    private func loadSelectedPhotos(_ items: [PhotosPickerItem]) async {
        for item in items {
            if let data = try? await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await MainActor.run {
                    withAnimation(.spring(response: 0.3)) {
                        viewModel.photos.append(image)
                    }
                }
            }
        }
        
        // Clear the selection
        await MainActor.run {
            selectedPhotos = []
        }
    }
}

// MARK: - Photo Grid
struct PhotoGrid: View {
    let photos: [UIImage]
    let onRemove: (Int) -> Void
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 2)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Photos")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(Array(photos.enumerated()), id: \.offset) { index, photo in
                    PhotoGridItem(
                        image: photo,
                        onRemove: { onRemove(index) }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Photo Grid Item
struct PhotoGridItem: View {
    let image: UIImage
    let onRemove: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 120)
                .clipped()
                .cornerRadius(12)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .padding(8)
        }
    }
}

// MARK: - Add Photo Button
struct AddPhotoButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            AddPhotoButtonContent(
                icon: icon,
                title: title,
                subtitle: subtitle
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Add Photo Button Content
struct AddPhotoButtonContent: View {
    let icon: String
    let title: String
    let subtitle: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator), lineWidth: 1)
        )
    }
}

// MARK: - Photo Tips View
struct PhotoTipsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Photo Tips")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 12) {
                PhotoTipRow(
                    icon: "lightbulb",
                    text: "Good lighting makes your whisky look more appealing"
                )
                
                PhotoTipRow(
                    icon: "viewfinder",
                    text: "Include the bottle label and your glass in the shot"
                )
                
                PhotoTipRow(
                    icon: "square.grid.3x3",
                    text: "Try different angles - overhead, side view, or close-up"
                )
                
                PhotoTipRow(
                    icon: "hand.raised",
                    text: "Keep hands steady for crisp, clear photos"
                )
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Photo Tip Row
struct PhotoTipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.accentColor)
                .frame(width: 20)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImageSelected: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
                parent.onImageSelected(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}