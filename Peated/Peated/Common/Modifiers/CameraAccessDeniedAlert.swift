import SwiftUI
import UIKit

/// Tells the user camera access was refused and offers the Settings app,
/// where the permission can be turned back on.
struct CameraAccessDeniedAlert: ViewModifier {
    @Environment(\.openURL) private var openURL
    @Binding var isPresented: Bool
    let message: String

    func body(content: Content) -> some View {
        content.alert("Camera Access Needed", isPresented: $isPresented) {
            Button("Open Settings") {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    openURL(settingsURL)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(message)
        }
    }
}

extension View {
    func cameraAccessDeniedAlert(isPresented: Binding<Bool>, message: String) -> some View {
        modifier(CameraAccessDeniedAlert(isPresented: isPresented, message: message))
    }
}
