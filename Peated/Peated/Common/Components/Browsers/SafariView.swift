import SwiftUI
import SafariServices

struct SafariView: UIViewControllerRepresentable {
  let url: URL
  var entersReaderIfAvailable: Bool = false
  var barCollapsingEnabled: Bool = true

  func makeUIViewController(context: Context) -> SFSafariViewController {
    let config = SFSafariViewController.Configuration()
    config.entersReaderIfAvailable = entersReaderIfAvailable
    config.barCollapsingEnabled = barCollapsingEnabled

    let vc = SFSafariViewController(url: url, configuration: config)
    vc.modalPresentationStyle = .pageSheet
    vc.dismissButtonStyle = .close
    return vc
  }

  func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
    // No-op
  }
}

