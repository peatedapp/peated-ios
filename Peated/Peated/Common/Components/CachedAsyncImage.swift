import SwiftUI

// Lightweight image cache + loader tuned for avatars and small images.
// Uses in-memory NSCache and URLCache-backed network requests with
// `.returnCacheDataElseLoad` to avoid unnecessary re-fetching.

final class ImageMemoryCache: NSObject, NSCacheDelegate {
  static let shared = ImageMemoryCache()
  private let cache = NSCache<NSURL, UIImage>()
  struct Metrics {
    var hits = 0
    var misses = 0
    var inserts = 0
    var evictions = 0
  }
  private(set) var metrics = Metrics()

  private override init() {
    super.init()
    cache.countLimit = 1000 // generous for small avatars
    cache.totalCostLimit = 50 * 1024 * 1024 // ~50 MB
    cache.delegate = self
  }

  func image(for url: URL) -> UIImage? {
    let img = cache.object(forKey: url as NSURL)
    if img != nil { metrics.hits += 1 } else { metrics.misses += 1 }
    return img
  }

  func insert(_ image: UIImage, for url: URL) {
    let cost = image.jpegData(compressionQuality: 0.7)?.count ?? 0
    cache.setObject(image, forKey: url as NSURL, cost: cost)
    metrics.inserts += 1
  }

  // NSCacheDelegate
  func cache(_ cache: NSCache<AnyObject, AnyObject>, willEvictObject obj: Any) {
    metrics.evictions += 1
  }
}

@MainActor
final class CachedImageLoader: ObservableObject {
  @Published var image: UIImage?

  private var currentTask: Task<Void, Never>?

  func load(from url: URL?) async {
    currentTask?.cancel()
    image = nil

    guard let url = url else { return }

    // Memory cache first
    if let cached = ImageMemoryCache.shared.image(for: url) {
      self.image = cached
      return
    }

    currentTask = Task { [weak self] in
      guard let self else { return }

      // Prefer cached data if available; otherwise load.
      var request = URLRequest(url: url)
      request.cachePolicy = .returnCacheDataElseLoad
      request.timeoutInterval = 30

      do {
        let (data, response) = try await URLSession.shared.data(for: request)

        // Verify basic response status when available
        if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
          return
        }
        if let img = UIImage(data: data) {
          ImageMemoryCache.shared.insert(img, for: url)
          if !Task.isCancelled {
            self.image = img
          }
        }
      } catch {
        // Ignore errors; placeholder will show.
      }
    }

    await currentTask?.value
  }
}

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
  let url: URL?
  let content: (Image) -> Content
  let placeholder: () -> Placeholder

  @StateObject private var loader = CachedImageLoader()

  var body: some View {
    // Show memory-cached image immediately to avoid placeholder flicker
    let memImage: UIImage? = {
      if let url { return ImageMemoryCache.shared.image(for: url) }
      return nil
    }()

    Group {
      if let uiImage = loader.image ?? memImage {
        content(Image(uiImage: uiImage))
      } else {
        placeholder()
      }
    }
    .task(id: url) {
      await loader.load(from: url)
    }
  }
}
