import Foundation
import UIKit

/// Warms the in-memory image cache so views can render without placeholder flicker.
actor _InFlightTracker {
    private var set = Set<URL>()
    func claim(_ url: URL) -> Bool {
        if set.contains(url) {
            return false
        }
        set.insert(url)
        return true
    }

    func release(_ url: URL) {
        set.remove(url)
    }
}

enum ImagePrefetcher {
    private static let tracker = _InFlightTracker()

    static func prefetch(urls: [URL], max: Int = 40) {
        // Deduplicate and cap
        var unique: [URL] = []
        var seen = Set<URL>()
        for u in urls {
            if !seen.contains(u) {
                seen.insert(u)
                unique.append(u)
            }
            if unique.count >= max {
                break
            }
        }

        guard !unique.isEmpty else { return }

        Task.detached(priority: .background) {
            for url in unique {
                // Skip if already in memory
                if ImageMemoryCache.shared.image(for: url) != nil {
                    continue
                }

                // Skip if request already in-flight
                let shouldFetch = await tracker.claim(url)
                if !shouldFetch {
                    continue
                }

                // Pull from URLCache if present, else fetch
                var request = URLRequest(url: url)
                request.cachePolicy = .returnCacheDataElseLoad
                request.timeoutInterval = 15
                do {
                    let (data, response) = try await URLSession.shared.data(for: request)
                    if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
                        continue
                    }
                    if let img = UIImage(data: data) {
                        ImageMemoryCache.shared.insert(img, for: url)
                    }
                } catch {
                    // Ignore failures; normal loader will handle later.
                }
                await tracker.release(url)
            }
        }
    }
}
