import Foundation
import PeatedAPI
import OpenAPIRuntime
#if canImport(UIKit)
import UIKit
#endif

public protocol ImageUploadServiceProtocol {
  func uploadTastingImage(tastingId: String, image: Data) async throws -> String
  func uploadTastingImages(tastingId: String, images: [Data]) async throws -> [String]
}

public actor ImageUploadService: ImageUploadServiceProtocol {
  private let apiClient: APIClient
  
  public init(apiClient: APIClient? = nil) {
    self.apiClient = apiClient ?? APIClient.shared
  }
  
  /// Upload a single image for a tasting
  public func uploadTastingImage(tastingId: String, image: Data) async throws -> String {
    guard let tastingIdDouble = Double(tastingId) else {
      throw APIError.requestFailed("Invalid tasting ID")
    }
    
    // Get the generated client
    let client = await apiClient.generatedClient
    
    // Convert image data to base64 and wrap in OpenAPIValueContainer
    let base64String = "data:image/jpeg;base64," + image.base64EncodedString()
    
    // Create the request with image data as base64  
    let response = try await client.updateTastingImage(
      .init(
        path: .init(tasting: tastingIdDouble),
        body: .json(.init(
          file: .init(stringLiteral: base64String)
        ))
      )
    )
    
    switch response {
    case .ok(let okResponse):
      switch okResponse.body {
      case .json(let payload):
        return payload.imageUrl
      }
    case .badRequest:
      throw APIError.requestFailed("Invalid image data")
    case .unauthorized:
      throw APIError.unauthorized
    case .notFound:
      throw APIError.notFound
    case .undocumented(let statusCode, _):
      throw APIError.unexpectedResponse(statusCode)
    default:
      throw APIError.invalidResponse
    }
  }
  
  /// Upload multiple images for a tasting
  public func uploadTastingImages(tastingId: String, images: [Data]) async throws -> [String] {
    var uploadedUrls: [String] = []
    
    // Upload images sequentially to avoid overwhelming the server
    // In the future, we might want to batch these or use parallel uploads with limits
    for imageData in images {
      do {
        let url = try await uploadTastingImage(tastingId: tastingId, image: imageData)
        uploadedUrls.append(url)
      } catch {
        // Log the error but continue with other uploads
        print("Failed to upload image: \(error)")
        // Optionally, you might want to throw here to fail fast
        // throw error
      }
    }
    
    return uploadedUrls
  }
}

// MARK: - UIImage Extension for Compression
#if canImport(UIKit)
public extension UIImage {
  /// Compress image for upload with reasonable quality
  func compressedForUpload(maxSizeKB: Int = 1024) -> Data? {
    let maxSizeBytes = maxSizeKB * 1024
    
    // Start with high quality and reduce if needed
    var compression: CGFloat = 0.9
    var imageData = self.jpegData(compressionQuality: compression)
    
    // Reduce quality until we're under the size limit
    while let data = imageData, data.count > maxSizeBytes && compression > 0.1 {
      compression -= 0.1
      imageData = self.jpegData(compressionQuality: compression)
    }
    
    // If still too large, resize the image
    if let data = imageData, data.count > maxSizeBytes {
      let ratio = CGFloat(maxSizeBytes) / CGFloat(data.count)
      let newSize = CGSize(
        width: size.width * sqrt(ratio),
        height: size.height * sqrt(ratio)
      )
      
      UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
      draw(in: CGRect(origin: .zero, size: newSize))
      let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
      UIGraphicsEndImageContext()
      
      return resizedImage?.jpegData(compressionQuality: 0.8)
    }
    
    return imageData
  }
}
#endif