import AVFoundation
import Foundation

/// Camera authorization for the scanner and photo capture screens.
enum CameraAccess {
    /// Asks for camera access when the user has not decided yet and reports on
    /// the main queue whether the camera can be used.
    static func request(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async { completion(granted) }
            }
        case .denied, .restricted:
            completion(false)
        @unknown default:
            completion(false)
        }
    }
}
