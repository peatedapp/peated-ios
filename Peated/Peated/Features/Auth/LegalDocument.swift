import Foundation

/// Public legal pages on peated.com that the app must link to for App Review.
enum LegalDocument: String, Identifiable {
    case terms
    case privacy

    var id: String {
        rawValue
    }

    var url: URL {
        switch self {
        case .terms: URL(string: "https://peated.com/terms")!
        case .privacy: URL(string: "https://peated.com/privacy")!
        }
    }
}
