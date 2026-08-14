import Foundation

enum PeatedWebURL {
    private static let baseURL = URL(string: "https://peated.com")!

    static func bottle(id: String) -> URL {
        baseURL
            .appendingPathComponent("bottles")
            .appendingPathComponent(id)
    }

    static func tasting(id: String) -> URL {
        baseURL
            .appendingPathComponent("tastings")
            .appendingPathComponent(id)
    }
}
