import Foundation
@testable import PeatedCore
import Testing

struct BottlePhotoIdentificationRepositoryTests {
    @Test
    func unmatchedLabelWithConflictsIsNotFound() async throws {
        let identification = try await identify(Self.response(
            classification: Self.classified(#"{"action": "no_match"}"#),
            suggestedNextStep: "manual_search"
        ))

        #expect(identification.outcome == .notFound)
        #expect(identification.searchQuery == "Lagavulin Distillers Edition")
        #expect(identification.manualBottleInput?.brandName == "Lagavulin")
        #expect(identification.manualBottleInput?.name == "Distillers Edition")
    }

    @Test
    func unmatchedLabelWithoutBottleDetailsIsUnidentified() async throws {
        let identification = try await identify(Self.response(
            fieldCandidates: #"""
            {"category": {"value": "single_malt", "confidence": 0.8, "sourceExtractorIndexes": [0]}}
            """#,
            classification: Self.classified(#"{"action": "no_match"}"#),
            suggestedNextStep: "manual_search"
        ))

        #expect(identification.outcome == .unidentified)
        #expect(identification.manualBottleInput?.category == .singleMalt)
    }

    @Test
    func ignoredClassificationIsUnidentified() async throws {
        let identification = try await identify(Self.response(
            classification: #"""
            {
              "status": "ignored",
              "reason": "The photo shows more than one bottle.",
              "artifacts": {"candidates": []}
            }
            """#,
            suggestedNextStep: "manual_search"
        ))

        #expect(identification.outcome == .unidentified)
    }

    @Test
    func downgradedMatchStillShowsMatchedBottle() async throws {
        let identification = try await identify(Self.response(
            classification: Self.classified(#"{"action": "match", "matchedBottle": \#(Self.bottle)}"#),
            suggestedNextStep: "manual_search"
        ))

        guard case let .matched(bottle) = identification.outcome else {
            Issue.record("Expected a matched bottle, got \(identification.outcome)")
            return
        }
        #expect(bottle.fullName == "Lagavulin Distillers Edition")
    }

    @Test
    func confirmedCreateIsProposed() async throws {
        let identification = try await identify(Self.response(
            classification: Self.classified(Self.createDecision),
            suggestedNextStep: "confirm_create",
            createToken: "create-token"
        ))

        #expect(identification.outcome == .proposed(
            BottlePhotoProposal(
                name: "Distillers Edition 2008",
                brandName: "Lagavulin",
                category: .singleMalt,
                abv: 43
            ),
            createToken: "create-token"
        ))
    }

    @Test
    func downgradedCreateIsNotFoundWithProposedInput() async throws {
        let identification = try await identify(Self.response(
            classification: Self.classified(Self.createDecision),
            suggestedNextStep: "manual_search"
        ))

        #expect(identification.outcome == .notFound)
        #expect(identification.manualBottleInput == CreateBottleInput(
            name: "Distillers Edition 2008",
            brandName: "Lagavulin",
            category: .singleMalt,
            abv: 43
        ))
    }

    private func identify(_ response: String) async throws -> BottlePhotoIdentification {
        let repository = BottlePhotoIdentificationRepository(apiClient: APIClient(
            transport: StubAPITransport([
                "identifyTastingBottleFromPhoto": [.json(200, response)]
            ])
        ))

        return try await repository.identifyBottlePhoto(
            fileDataUrl: "data:image/jpeg;base64,\(Data([0xFF, 0xD8]).base64EncodedString())",
            idempotencyKey: "photo-key"
        )
    }

    private static func classified(_ decision: String) -> String {
        """
        {
          "status": "classified",
          "decision": \(decision),
          "artifacts": {"candidates": [{"fullName": "Lagavulin 16-year-old"}]}
        }
        """
    }

    private static let labelFieldCandidates = """
    {
      "brand": {"value": "Lagavulin", "confidence": 0.9, "sourceExtractorIndexes": [0]},
      "expression": {"value": "Distillers Edition", "confidence": 0.85, "sourceExtractorIndexes": [0]},
      "category": {"value": "single_malt", "confidence": 0.8, "sourceExtractorIndexes": [0]},
      "abv": {"value": 43, "confidence": 0.8, "sourceExtractorIndexes": [0]}
    }
    """

    private static let createDecision = """
    {
      "action": "create_bottle",
      "proposedBottle": {
        "name": "Distillers Edition 2008",
        "series": null,
        "category": "single_malt",
        "edition": null,
        "statedAge": null,
        "abv": 43,
        "caskStrength": null,
        "singleCask": null,
        "maturation": null,
        "caskNumber": null,
        "outturn": null,
        "vintageYear": 2008,
        "releaseYear": null,
        "brand": {"id": 7, "name": "Lagavulin"},
        "distillers": [],
        "bottler": null
      }
    }
    """

    private static let bottle = """
    {
      "id": 42,
      "peatedId": "B0042",
      "fullName": "Lagavulin Distillers Edition",
      "name": "Distillers Edition",
      "brand": {
        "id": 7,
        "peatedId": "E0007",
        "name": "Lagavulin",
        "kind": "brand",
        "totalTastings": 0,
        "publicReviewAndTastingCount": 0,
        "totalBottles": 1,
        "isFollowing": false,
        "createdAt": "2026-01-01T00:00:00.000Z",
        "updatedAt": "2026-01-01T00:00:00.000Z"
      },
      "medianScore": null,
      "minScore": null,
      "maxScore": null,
      "memberScoreCount": 0,
      "externalScoreCount": 0,
      "raterCount": 0,
      "scoreCount": 0,
      "reviewScoreBandCounts": {"mediocre": 0, "good": 0, "very_good": 0, "outstanding": 0, "unicorn": 0},
      "tastingBandCounts": {"mediocre": 0, "good": 0, "very_good": 0, "outstanding": 0, "unicorn": 0},
      "totalTastings": 0,
      "publicReviewAndTastingCount": 0,
      "notedReviewAndTastingCount": 0,
      "createdAt": "2026-01-01T00:00:00.000Z",
      "updatedAt": "2026-01-01T00:00:00.000Z",
      "isFavorite": false,
      "isLibrary": false,
      "hasTasted": false
    }
    """

    private static func response(
        fieldCandidates: String = labelFieldCandidates,
        classification: String,
        suggestedNextStep: String,
        createToken: String? = nil
    ) -> String {
        """
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
            "fieldCandidates": \(fieldCandidates),
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
          "classification": \(classification),
          "suggestedNextStep": "\(suggestedNextStep)",
          "diagnostics": {
            "extraction": {"status": "found", "summary": "Lagavulin Distillers Edition"},
            "candidates": {"count": 1},
            "classification": {
              "status": "classified",
              "action": null,
              "confidence": null,
              "reason": null
            }
          },
          "createToken": \(createToken.map { "\"\($0)\"" } ?? "null")
        }
        """
    }
}
