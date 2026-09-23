import Foundation

enum PeatedWebURL {
    private static let baseURL = URL(string: "https://peated.com")!

    static func bottle(id: String) -> URL {
        baseURL
            .appendingPathComponent("bottles")
            .appendingPathComponent(id)
    }

    static func entity(id: String) -> URL {
        baseURL
            .appendingPathComponent("entities")
            .appendingPathComponent(id)
    }

    static func tasting(id: String) -> URL {
        baseURL
            .appendingPathComponent("tastings")
            .appendingPathComponent(id)
    }

    static func memberReview(id: String) -> URL {
        baseURL
            .appendingPathComponent("reviews")
            .appendingPathComponent(id)
    }
}
