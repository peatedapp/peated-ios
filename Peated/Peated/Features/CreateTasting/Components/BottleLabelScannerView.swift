import SwiftUI
import VisionKit

struct BottleLabelScannerView: View {
    @Environment(\.dismiss) private var dismiss
    let onSearch: (String) -> Void

    @State private var searchText = ""
    @State private var hasEditedSearchText = false
    @State private var scannerErrorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScannerCameraView(
                    onTextChanged: handleRecognizedText,
                    onScannerError: handleScannerError
                )
                .ignoresSafeArea()

                reviewPanel
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
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text(scannerErrorMessage ?? "The label scanner is unavailable.")
            }
        }
    }

    private var reviewPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(searchText.isEmpty ? "Point the camera at the front label" : "Review detected text")
                    .font(.headline)
                    .foregroundColor(.text)

                Text("Keep the bottle steady and make sure the brand and bottle name are visible.")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }

            TextField("Bottle name", text: editableSearchText)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled(false)
                .submitLabel(.search)
                .inputBox()
                .onSubmit(search)

            Button(action: search) {
                HStack {
                    Image(systemName: "magnifyingglass")
                    Text("Search Bottles")
                        .fontWeight(.medium)
                }
                .foregroundColor(.onBrand)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.brand)
                .cornerRadius(10)
            }
            .disabled(trimmedSearchText.isEmpty)
            .opacity(trimmedSearchText.isEmpty ? 0.5 : 1)
        }
        .padding()
        .background(Color.background.opacity(0.94))
    }

    private var editableSearchText: Binding<String> {
        Binding(
            get: { searchText },
            set: { newValue in
                hasEditedSearchText = true
                searchText = newValue
            }
        )
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

    private var trimmedSearchText: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func handleRecognizedText(_ text: String) {
        guard !hasEditedSearchText, !text.isEmpty else { return }
        if searchText.isEmpty || text.count > searchText.count {
            searchText = text
        }
    }

    private func handleScannerError(_ message: String) {
        scannerErrorMessage = message
    }

    private func search() {
        guard !trimmedSearchText.isEmpty else { return }
        onSearch(trimmedSearchText)
        dismiss()
    }
}

private extension BottleLabelScannerView {
    struct ScannerCameraView: UIViewControllerRepresentable {
        let onTextChanged: (String) -> Void
        let onScannerError: (String) -> Void

        func makeUIViewController(context: Context) -> DataScannerViewController {
            let scanner = DataScannerViewController(
                recognizedDataTypes: [.text()],
                qualityLevel: .balanced,
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
            guard !context.coordinator.didAttemptStart else { return }

            context.coordinator.didAttemptStart = true
            do {
                try scanner.startScanning()
            } catch {
                onScannerError("We couldn't start the label scanner. You can still search by name.")
            }
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

        init(_ parent: ScannerCameraView) {
            self.parent = parent
        }

        func dataScanner(
            _: DataScannerViewController,
            didAdd _: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            updateText(from: allItems)
        }

        func dataScanner(
            _: DataScannerViewController,
            didUpdate _: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            updateText(from: allItems)
        }

        func dataScanner(
            _: DataScannerViewController,
            didRemove _: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            updateText(from: allItems)
        }

        func dataScanner(
            _: DataScannerViewController,
            becameUnavailableWithError _: DataScannerViewController.ScanningUnavailable
        ) {
            parent.onScannerError(
                "The label scanner became unavailable. You can still search by name."
            )
        }

        private func updateText(from items: [RecognizedItem]) {
            let observations = items.compactMap { item -> BottleLabelSearchText.Observation? in
                guard case let .text(text) = item else { return nil }
                return BottleLabelSearchText.Observation(
                    text: text.transcript,
                    x: Double(text.bounds.topLeft.x),
                    y: Double(text.bounds.topLeft.y)
                )
            }
            parent.onTextChanged(BottleLabelSearchText.query(from: observations))
        }
    }
}
