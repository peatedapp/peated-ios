import Foundation

extension Date {
    /// Relative time for feed headers, like "2 hours ago", matching the web.
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: self, relativeTo: Date())
    }
}
