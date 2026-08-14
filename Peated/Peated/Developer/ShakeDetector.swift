import SwiftUI
import UIKit

#if DEBUG
    extension UIWindow {
        override open func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
            super.motionEnded(motion, with: event)

            if motion == .motionShake {
                NotificationCenter.default.post(name: .deviceDidShake, object: nil)
            }
        }
    }

    extension Notification.Name {
        static let deviceDidShake = Notification.Name("deviceDidShake")
    }

    struct ShakeDetector: ViewModifier {
        let action: () -> Void

        func body(content: Content) -> some View {
            content
                .onReceive(NotificationCenter.default.publisher(for: .deviceDidShake)) { _ in
                    action()
                }
        }
    }

    extension View {
        func onShake(perform action: @escaping () -> Void) -> some View {
            modifier(ShakeDetector(action: action))
        }
    }
#else
    extension View {
        func onShake(perform _: @escaping () -> Void) -> some View {
            self
        }
    }
#endif
