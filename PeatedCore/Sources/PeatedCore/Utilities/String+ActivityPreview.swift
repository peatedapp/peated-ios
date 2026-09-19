import Foundation

public extension String {
    /// Collapses whitespace and cuts at a word boundary near the limit, matching
    /// the web feed's excerpt rule. Returns nil for blank text.
    func activityPreview(limit: Int = 160) -> String? {
        let normalized = split(whereSeparator: \.isWhitespace).joined(separator: " ")
        guard !normalized.isEmpty else { return nil }
        guard normalized.count > limit else { return normalized }

        let window = String(normalized.prefix(limit + 1))
        let cutoff = window.lastIndex(of: " ").map { window.distance(from: window.startIndex, to: $0) } ?? 0
        let end = cutoff > 0 ? cutoff : limit
        let clipped = String(normalized.prefix(end))
        return clipped.trimmingCharacters(in: .whitespaces) + "…"
    }
}
