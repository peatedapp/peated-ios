import SafariServices
import SwiftUI

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    var entersReaderIfAvailable: Bool = false
    var barCollapsingEnabled: Bool = true

    func makeUIViewController(context _: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = entersReaderIfAvailable
        config.barCollapsingEnabled = barCollapsingEnabled

        let vc = SFSafariViewController(url: url, configuration: config)
        vc.modalPresentationStyle = .pageSheet
        vc.dismissButtonStyle = .close
        return vc
    }

    func updateUIViewController(_: SFSafariViewController, context _: Context) {
        // No-op
    }
}
