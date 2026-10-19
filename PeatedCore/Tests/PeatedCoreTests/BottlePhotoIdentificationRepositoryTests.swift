import Foundation
@testable import PeatedCore
import Testing

struct BottlePhotoIdentificationRepositoryTests {
    @Test
    func unmatchedLabelWithConflictsReturnsManualOutcome() async throws {
        let repository = BottlePhotoIdentificationRepository(apiClient: APIClient(
            transport: StubAPITransport([
                "identifyTastingBottleFromPhoto": [.json(200, Self.noMatchResponse)]
            ])
        ))

        let identification = try await repository.identifyBottlePhoto(
            fileDataUrl: "data:image/jpeg;base64,\(Data([0xFF, 0xD8]).base64EncodedString())",
            idempotencyKey: "photo-key"
        )

        #expect(identification.outcome == .manual)
        #expect(identification.searchQuery == "Lagavulin Distillers Edition")
        #expect(identification.manualBottleInput?.brandName == "Lagavulin")
        #expect(identification.manualBottleInput?.name == "Distillers Edition")
    }

    private static let noMatchResponse = """
    {
      "pendingImage": {
        "id": "pending-1",
        "imageUrl": "https://api.peated.com/uploads/pending-1.webp",
        "expiresAt": "2026-10-19T13:00:00.000Z"
      },
      "imageEvidence": {
        "sourceImageId": "pending-1",
        "sourceImageHash": "hash-1",
        "extractors": [
          {
            "kind": "vision",
            "model": "gpt-5",
            "confidence": 0.82,
            "textSpans": [{"text": "Lagavulin Distillers Edition", "confidence": 0.82}],
            "observations": ["Single bottle label is readable."]
          }
        ],
        "fieldCandidates": {
          "brand": {"value": "Lagavulin", "confidence": 0.9, "sourceExtractorIndexes": [0]},
          "expression": {"value": "Distillers Edition", "confidence": 0.85, "sourceExtractorIndexes": [0]},
          "category": {"value": "single_malt", "confidence": 0.8, "sourceExtractorIndexes": [0]},
          "abv": {"value": 43, "confidence": 0.8, "sourceExtractorIndexes": [0]}
        },
        "photoSuitability": {
          "isSingleBottlePhoto": true,
          "labelReadable": true,
          "suitableAsTastingImage": true,
          "suitableAsBottleImage": true,
          "reason": "The label is readable."
        },
        "conflicts": [
          {"field": "abv", "values": [43, "43%", null], "reason": "Extractors disagree on ABV."}
        ]
      },
      "classification": {
        "status": "classified",
        "decision": {"action": "no_match"},
        "artifacts": {"candidates": [{"fullName": "Lagavulin 16-year-old"}]}
      },
      "suggestedNextStep": "manual_search",
      "diagnostics": {
        "extraction": {"status": "found", "summary": "Lagavulin Distillers Edition"},
        "candidates": {"count": 1},
        "classification": {
          "status": "classified",
          "action": "no_match",
          "confidence": null,
          "reason": "No existing Peated bottle matched the label details."
        }
      },
      "createToken": null
    }
    """
}
