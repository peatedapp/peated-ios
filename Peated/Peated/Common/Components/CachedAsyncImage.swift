import SwiftUI

// Lightweight image cache + loader tuned for avatars and small images.
// Uses in-memory NSCache and URLCache-backed network requests with
// `.returnCacheDataElseLoad` to avoid unnecessary re-fetching.

final class ImageMemoryCache {
  static let shared = ImageMemoryCache()
  private let cache = NSCache<NSURL, UIImage>()

  private init() {
    cache.countLimit = 1000 // generous for small avatars
    cache.totalCostLimit = 50 * 1024 * 1024 // ~50 MB
  }

  func image(for url: URL) -> UIImage? {
    cache.object(forKey: url as NSURL)
  }

  func insert(_ image: UIImage, for url: URL) {
    let cost = image.jpegData(compressionQuality: 0.7)?.count ?? 0
    cache.setObject(image, forKey: url as NSURL, cost: cost)
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
