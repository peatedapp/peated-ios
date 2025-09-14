import SwiftUI
import AVFoundation
import PeatedCore

struct BarcodeScannerView: View {
  @Environment(\.dismiss) private var dismiss
  let onBarcodeScanned: (String) -> Void
  
  @State private var isScanning = false
  @State private var scannedCode: String?
  @State private var showingAlert = false
  @State private var alertMessage = ""
  
  var body: some View {
    NavigationStack {
      ZStack {
        // Camera view
        BarcodeScannerCameraView(
          onBarcodeScanned: handleBarcodeScanned,
          isScanning: $isScanning
        )
        .ignoresSafeArea()
        
        // Overlay
        VStack {
          Spacer()
          
          // Scanning frame
          RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
            .stroke(Color.brand, lineWidth: DesignSystem.Border.thick)
            .frame(width: 280, height: 280)
            .overlay(
              VStack {
                if isScanning {
                  ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .brand))
                    .scaleEffect(1.5)
                }
              }
            )
          
          Spacer()
          
          // Instructions
          VStack(spacing: DesignSystem.Spacing.small) {
            Text("Position barcode within frame")
              .font(.system(size: DesignSystem.FontSize.title, weight: .medium))
              .foregroundColor(.onStatus)
            
            Text("Scanning will happen automatically")
              .font(.system(size: DesignSystem.FontSize.body))
              .foregroundColor(.onStatus.opacity(DesignSystem.Opacity.dimmed))
          }
          .padding(.horizontal, DesignSystem.Spacing.screenPadding)
          .padding(.bottom, 50)
        }
      }
      .navigationTitle("Scan Barcode")
      .navigationBarTitleDisplayMode(.inline)
      .navigationChrome()
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel") {
            dismiss()
          }
        }
      }
      .alert("Barcode Scanned", isPresented: $showingAlert) {
        Button("OK") {
          dismiss()
        }
      } message: {
        Text(alertMessage)
      }
    }
  }
  
  private func handleBarcodeScanned(_ code: String) {
    // Prevent multiple scans
    guard scannedCode == nil else { return }
    
    scannedCode = code
    isScanning = true
    
    // Haptic feedback
    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    
    // Call the callback
    onBarcodeScanned(code)
    
    // Show success and dismiss
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      dismiss()
    }
  }
}

// MARK: - Camera View
struct BarcodeScannerCameraView: UIViewRepresentable {
  let onBarcodeScanned: (String) -> Void
  @Binding var isScanning: Bool
  
  func makeUIView(context: Context) -> UIView {
    let view = UIView(frame: UIScreen.main.bounds)
    
    // Create capture session
    let captureSession = AVCaptureSession()
    context.coordinator.captureSession = captureSession
    
    guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
      return view
    }
    
    let videoInput: AVCaptureDeviceInput
    
    do {
      videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
    } catch {
      return view
    }
    
    if captureSession.canAddInput(videoInput) {
      captureSession.addInput(videoInput)
    } else {
      return view
    }
    
    let metadataOutput = AVCaptureMetadataOutput()
    
    if captureSession.canAddOutput(metadataOutput) {
      captureSession.addOutput(metadataOutput)
      
      metadataOutput.setMetadataObjectsDelegate(context.coordinator, queue: DispatchQueue.main)
      metadataOutput.metadataObjectTypes = [
        .ean8,
        .ean13,
        .pdf417,
        .qr,
        .code128,
        .code39,
        .code93,
        .upce
      ]
    } else {
      return view
    }
    
    // Add preview layer
    let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
    previewLayer.frame = view.layer.bounds
    previewLayer.videoGravity = .resizeAspectFill
    view.layer.addSublayer(previewLayer)
    context.coordinator.previewLayer = previewLayer
    
    // Start capture session
    DispatchQueue.global(qos: .userInitiated).async {
      captureSession.startRunning()
    }
    
    return view
  }
  
  func updateUIView(_ uiView: UIView, context: Context) {
    // Update preview layer frame if needed
    if let previewLayer = context.coordinator.previewLayer {
      previewLayer.frame = uiView.layer.bounds
    }
  }
  
  static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
    coordinator.captureSession?.stopRunning()
  }
  
  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }
  
  class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
    let parent: BarcodeScannerCameraView
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    init(_ parent: BarcodeScannerCameraView) {
      self.parent = parent
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput,
                       didOutput metadataObjects: [AVMetadataObject],
                       from connection: AVCaptureConnection) {
      // Check if we found a barcode
      guard let metadataObject = metadataObjects.first,
            let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
            let stringValue = readableObject.stringValue else {
        return
      }
      
      // Don't scan if already scanning
      if !parent.isScanning {
        parent.onBarcodeScanned(stringValue)
      }
    }
  }
}
