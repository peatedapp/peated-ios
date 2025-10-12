import Foundation
import Testing
@testable import PeatedAPI

@Suite("Decoding Debug Tests")
struct DecodingDebugTests {

    @Test("Decode real API response")
    func testDecodeRealResponse() async throws {
        // Fetch real API response
        let url = URL(string: "https://api.peated.com/v1/tastings?limit=1")!
        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            Issue.record("Not an HTTP response")
            return
        }

        print("Response status: \(httpResponse.statusCode)")
        print("Data size: \(data.count) bytes")

        // Print raw JSON for inspection
        if let jsonString = String(data: data, encoding: .utf8) {
            print("Raw JSON:")
            print(jsonString)
        }

        // Try to decode using the generated type
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let decoded = try decoder.decode(
                Operations.listTastings.Output.Ok.Body.jsonPayload.self,
                from: data
            )
            print("✅ Successfully decoded! Got \(decoded.results.count) results")
        } catch {
            print("❌ Decoding failed: \(error)")

            if let decodingError = error as? DecodingError {
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("Missing key '\(key.stringValue)' at path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                    print("Debug description: \(context.debugDescription)")

                case .typeMismatch(let type, let context):
                    print("Type mismatch for type \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                    print("Debug description: \(context.debugDescription)")
                    if let underlyingError = context.underlyingError {
                        print("Underlying error: \(underlyingError)")
                    }

                case .valueNotFound(let type, let context):
                    print("Value not found for type \(type) at path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                    print("Debug description: \(context.debugDescription)")

                case .dataCorrupted(let context):
                    print("Data corrupted at path: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                    print("Debug description: \(context.debugDescription)")
                    if let underlyingError = context.underlyingError {
                        print("Underlying error: \(underlyingError)")
                    }

                @unknown default:
                    print("Unknown decoding error")
                }
            }

            throw error
        }
    }
}
