import Foundation
import PeatedAPI
import OpenAPIRuntime

public enum RatingValue: Int, CaseIterable {
  case pass = -1
  case none = 0
  case sip = 1
  case savor = 2
  
  public var displayName: String {
    switch self {
    case .pass: return "Pass"
    case .none: return "No Rating"
    case .sip: return "Sip"
    case .savor: return "Savor"
    }
  }
  
  public var emoji: String {
    switch self {
    case .pass: return "👎"
    case .none: return ""
    case .sip: return "👍"
    case .savor: return "👍👍"
    }
  }
}

public extension Operations.createTasting.Input.Body.jsonPayload {
  static func makeRating(_ value: RatingValue) -> ratingPayload? {
    guard value != .none else { return nil }
    
    // The anyOf is generated as value1, value2, value3
    // We need to determine which one to use based on the actual const values
    switch value.rawValue {
    case -1:
      return ratingPayload(
        value1: OpenAPIValueContainer(-1),
        value2: nil,
        value3: nil
      )
    case 1:
      return ratingPayload(
        value1: nil,
        value2: OpenAPIValueContainer(1),
        value3: nil
      )
    case 2:
      return ratingPayload(
        value1: nil,
        value2: nil,
        value3: OpenAPIValueContainer(2)
      )
    default:
      return nil
    }
  }
}

// Helper to extract rating from API response
public func extractRating<T>(from ratingPayload: T?) -> Double where T: Any {
  guard let ratingPayload = ratingPayload else { return 0.0 }
  
  // Use reflection to find the actual value
  let mirror = Mirror(reflecting: ratingPayload)
  
  for child in mirror.children {
    if let container = child.value as? OpenAPIValueContainer {
      if let intValue = container.value as? Int {
        return Double(intValue)
      }
      if let doubleValue = container.value as? Double {
        return doubleValue
      }
    }
  }
  
  return 0.0
}