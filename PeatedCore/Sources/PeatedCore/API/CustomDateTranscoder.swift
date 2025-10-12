import Foundation
import PeatedAPI

struct CustomDateTranscoder: DateTranscoder {
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    
    init() {
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Create a fresh formatter for each decode to avoid mutation issues
            let formatterWithFractional = ISO8601DateFormatter()
            formatterWithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

            // Try with fractional seconds first
            if let date = formatterWithFractional.date(from: dateString) {
                return date
            }

            // Fallback to without fractional seconds
            let formatterWithoutFractional = ISO8601DateFormatter()
            formatterWithoutFractional.formatOptions = .withInternetDateTime
            if let date = formatterWithoutFractional.date(from: dateString) {
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
            let formatter = ISO8601DateFormatter()
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