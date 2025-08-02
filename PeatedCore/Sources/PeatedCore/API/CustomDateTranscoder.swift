import Foundation
import PeatedAPI

struct CustomDateTranscoder: DateTranscoder {
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    init() {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try with fractional seconds first
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            // Fallback to without fractional seconds
            formatter.formatOptions = .withInternetDateTime
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Expected date string to be ISO8601-formatted"
            )
        }
        
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            try container.encode(formatter.string(from: date))
        }
    }
    
    func encode(_ date: Date) throws -> String {
        let data = try encoder.encode(date)
        return String(data: data, encoding: .utf8)!.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
    }
    
    func decode(_ dateString: String) throws -> Date {
        let data = "\"\(dateString)\"".data(using: .utf8)!
        return try decoder.decode(Date.self, from: data)
    }
}