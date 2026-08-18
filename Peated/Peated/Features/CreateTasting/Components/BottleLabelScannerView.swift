import PhotosUI
import SwiftUI
import VisionKit

struct BottleLabelScannerView: View {
    @Environment(\.dismiss) private var dismiss
    let onImageSelected: (UIImage) -> Void

    @State private var captureRequest = 0
    @State private var isCapturing = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var scannerErrorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScannerCameraView(
                    captureRequest: captureRequest,
                    onPhotoCaptured: finish,
                    onScannerError: handleScannerError
                )
                .ignoresSafeArea()

                capturePanel
            }
            .navigationTitle("Scan Bottle Label")
            .navigationBarTitleDisplayMode(.inline)
            .navigationChrome()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Label Scanner Unavailable", isPresented: scannerErrorBinding) {
                Button("OK") {}
            } message: {
                Text(scannerErrorMessage ?? "The label scanner is unavailable.")
            }
            .onChange(of: selectedPhoto) { _, item in
                guard let item else { return }
                Task { await loadPhoto(item) }
            }
        }
    }

    private var capturePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Fill the frame with the front label")
                    .font(.headline)
                    .foregroundColor(.text)
                Text("Make sure the brand, bottle name, age, and ABV are readable.")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            Button {
                isCapturing = true
                captureRequest += 1
            } label: {
                Label(
                    isCapturing ? "Capturing..." : "Identify This Bottle",
                    systemImage: "camera.fill"
                )
                .fontWeight(.medium)
                .foregroundColor(.onBrand)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.brand)
                .cornerRadius(10)
            }
            .disabled(isCapturing)

            PhotosPicker(selection: $selectedPhoto, matching: .images) {
                Label("Choose Photo", systemImage: "photo.on.rectangle")
                    .fontWeight(.medium)
                    .foregroundColor(.brand)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.brand.opacity(0.1))
                    .cornerRadius(10)
            }
            .disabled(isCapturing)
        }
        .padding()
        .background(Color.background.opacity(0.94))
    }

    private var scannerErrorBinding: Binding<Bool> {
        Binding(
            get: { scannerErrorMessage != nil },
            set: { isPresented in
                if !isPresented {
                    scannerErrorMessage = nil
                }
            }
        )
    }

    private func finish(_ image: UIImage) {
        isCapturing = false
        onImageSelected(image)
        dismiss()
    }

    private func handleScannerError(_ message: String) {
        isCapturing = false
        scannerErrorMessage = message
    }

    private func loadPhoto(_ item: PhotosPickerItem) async {
        isCapturing = true
        defer {
            isCapturing = false
            selectedPhoto = nil
        }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data)
            else {
                throw BottleLabelScannerError.invalidImage
            }
            finish(image)
        } catch {
            handleScannerError("We couldn't load that photo. Choose another image and try again.")
        }
    }
}

private extension BottleLabelScannerView {
    struct ScannerCameraView: UIViewControllerRepresentable {
        let captureRequest: Int
        let onPhotoCaptured: (UIImage) -> Void
        let onScannerError: (String) -> Void

        func makeUIViewController(context: Context) -> DataScannerViewController {
            let scanner = DataScannerViewController(
                recognizedDataTypes: [.text()],
                qualityLevel: .accurate,
                recognizesMultipleItems: true,
                isHighFrameRateTrackingEnabled: false,
                isPinchToZoomEnabled: true,
                isGuidanceEnabled: true,
                isHighlightingEnabled: true
            )
            scanner.delegate = context.coordinator
            return scanner
        }

        func updateUIViewController(_ scanner: DataScannerViewController, context: Context) {
            context.coordinator.parent = self

            if !context.coordinator.didAttemptStart {
                context.coordinator.didAttemptStart = true
                do {
                    try scanner.startScanning()
                } catch {
                    onScannerError("We couldn't start the label scanner. Choose a photo instead.")
                }
            }

            guard captureRequest > context.coordinator.handledCaptureRequest else { return }
            context.coordinator.handledCaptureRequest = captureRequest
            context.coordinator.capturePhoto(from: scanner)
        }

        static func dismantleUIViewController(
            _ scanner: DataScannerViewController,
            coordinator _: ScannerCameraCoordinator
        ) {
            scanner.stopScanning()
        }

        func makeCoordinator() -> ScannerCameraCoordinator {
            ScannerCameraCoordinator(self)
        }
    }

    @MainActor
    final class ScannerCameraCoordinator: NSObject, DataScannerViewControllerDelegate {
        var parent: ScannerCameraView
        var didAttemptStart = false
        var handledCaptureRequest = 0

        init(_ parent: ScannerCameraView) {
            self.parent = parent
        }

        func capturePhoto(from scanner: DataScannerViewController) {
            Task {
                do {
                    let image = try await scanner.capturePhoto()
                    parent.onPhotoCaptured(image)
                } catch {
                    parent.onScannerError(
                        "We couldn't capture that photo. Hold the bottle steady and try again."
                    )
                }
            }
        }

        func dataScanner(
            _: DataScannerViewController,
            becameUnavailableWithError _: DataScannerViewController.ScanningUnavailable
        ) {
            parent.onScannerError(
                "The label scanner became unavailable. Choose a photo instead."
            )
        }
    }

    enum BottleLabelScannerError: Error {
        case invalidImage
    }
}
