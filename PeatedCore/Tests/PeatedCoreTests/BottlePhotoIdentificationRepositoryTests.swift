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
            abv: 43,
            vintageYear: 2008
        ))
    }

    @Test
    func downgradedCreatePrefillsReleaseDetailsFromProposedBottle() async throws {
        let identification = try await identify(Self.response(
            classification: Self.classified(Self.releaseCreateDecision),
            suggestedNextStep: "manual_search"
        ))

        #expect(identification.manualBottleInput == CreateBottleInput(
            name: "Distillers Edition",
            brandName: "Lagavulin",
            category: .singleMalt,
            abv: 54.2,
            edition: "Feis Ile 2024",
            distillers: [.existing(id: 12, name: "Lagavulin"), .new(name: "Port Ellen")],
            singleCask: true,
            caskStrength: true,
            vintageYear: 2009,
            releaseYear: 2024
        ))
    }

    @Test
    func unmatchedLabelPrefillsReleaseDetailsFromFieldCandidates() async throws {
        let identification = try await identify(Self.response(
            fieldCandidates: Self.releaseFieldCandidates,
            classification: Self.classified(#"{"action": "no_match"}"#),
            suggestedNextStep: "manual_search"
        ))

        #expect(identification.manualBottleInput == CreateBottleInput(
            name: "Distillers Edition",
            brandName: "Lagavulin",
            edition: "Islay Festival",
            distillers: [.new(name: "Lagavulin")],
            singleCask: true,
            caskStrength: true,
            vintageYear: 2010,
            releaseYear: 2023
        ))
    }

    @Test
    func progressEventsArriveBeforeTheResult() async throws {
        let log = ProgressLog()
        let identification = try await identify(
            stream: [
                ": \n\n",
                Self.event("message", #"{"type": "photo", "pendingImage": \#(Self.pendingImage)}"#),
                Self.event("message", #"{"type": "label", "imageEvidence": {}}"#),
                ": \n\n",
                Self.event("message", #"{"type": "candidates", "bottles": [\#(Self.bottle)]}"#),
                Self.event("message", #"{"type": "step", "step": "checking_peated"}"#),
                Self.event("message", #"{"type": "step", "step": "checking_web"}"#),
                Self.event("message", #"{"type": "future_event"}"#),
                Self.event("message", #"{"type": "step", "step": "future_step"}"#),
                Self.event("done", Self.response(
                    classification: Self.classified(#"{"action": "no_match"}"#),
                    suggestedNextStep: "manual_search"
                ))
            ].joined(),
            onProgress: { await log.append($0) }
        )

        let progress = await log.events
        #expect(progress.count == 5)
        #expect(progress.first == .photo(pendingImageId: "pending-1"))
        #expect(progress.dropFirst().first == .labelRead)
        guard case let .candidates(bottles) = progress.dropFirst(2).first else {
            Issue.record("Expected likely matches, got \(progress)")
            return
        }
        #expect(bottles.map(\.fullName) == ["Lagavulin Distillers Edition"])
        #expect(Array(progress.suffix(2)) == [.step(.checkingPeated), .step(.checkingWeb)])
        #expect(identification.outcome == .notFound)
        #expect(identification.pendingImageId == "pending-1")
    }

    @Test
    func errorEventEndsTheLookup() async throws {
        let log = ProgressLog()
        let stream = [
            Self.event("message", #"{"type": "photo", "pendingImage": \#(Self.pendingImage)}"#),
            Self.event(
                "error",
                #"{"defined": false, "code": "SERVICE_UNAVAILABLE", "status": 503, "message": "Unavailable"}"#
            ),
            Self.event("done", Self.response(
                classification: Self.classified(#"{"action": "no_match"}"#),
                suggestedNextStep: "manual_search"
            ))
        ].joined()

        await #expect {
            try await identify(stream: stream, onProgress: { await log.append($0) })
        } throws: { error in
            guard case let APIError.requestFailed(message) = error else { return false }
            return message.contains("temporarily unavailable")
        }
        #expect(await log.events == [.photo(pendingImageId: "pending-1")])
    }

    @Test
    func streamWithoutResultIsInvalid() async throws {
        let stream = ": \n\n" + Self.event("message", #"{"type": "step", "step": "comparing"}"#)

        await #expect {
            try await identify(stream: stream)
        } throws: { error in
            guard case APIError.invalidResponse = error else { return false }
            return true
        }
    }

    private func identify(_ response: String) async throws -> BottlePhotoIdentification {
        try await identify(stream: Self.event("done", response))
    }

    private func identify(
        stream: String,
        onProgress: @escaping @Sendable (BottlePhotoProgress) async -> Void = { _ in }
    ) async throws -> BottlePhotoIdentification {
        let repository = BottlePhotoIdentificationRepository(apiClient: APIClient(
            transport: StubAPITransport([
                "identifyTastingBottleFromPhoto": [.eventStream(stream)]
            ])
        ))

        return try await repository.identifyBottlePhoto(
            fileDataUrl: "data:image/jpeg;base64,\(Data([0xFF, 0xD8]).base64EncodedString())",
            idempotencyKey: "photo-key",
            onProgress: onProgress
        )
    }

    /// One server-sent event. Multi-line data becomes several `data:` lines.
    private static func event(_ name: String, _ data: String) -> String {
        let lines = data.split(separator: "\n", omittingEmptySubsequences: false)
            .map { "data: \($0)" }
            .joined(separator: "\n")
        return "event: \(name)\n\(lines)\n\n"
    }

    private static let pendingImage = """
    {
      "id": "pending-1",
      "imageUrl": "https://api.peated.com/uploads/pending-1.webp",
      "expiresAt": "2026-10-19T13:00:00.000Z"
    }
    """

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

    private static let releaseFieldCandidates = """
    {
      "brand": {"value": "Lagavulin", "confidence": 0.9, "sourceExtractorIndexes": [0]},
      "expression": {"value": "Distillers Edition", "confidence": 0.85, "sourceExtractorIndexes": [0]},
      "edition": {"value": " Islay Festival ", "confidence": 0.8, "sourceExtractorIndexes": [0]},
      "distillery": {"value": ["Lagavulin", " "], "confidence": 0.8, "sourceExtractorIndexes": [0]},
      "vintageYear": {"value": 2010, "confidence": 0.8, "sourceExtractorIndexes": [0]},
      "releaseYear": {"value": 2023, "confidence": 0.8, "sourceExtractorIndexes": [0]},
      "caskStrength": {"value": true, "confidence": 0.8, "sourceExtractorIndexes": [0]},
      "singleCask": {"value": true, "confidence": 0.8, "sourceExtractorIndexes": [0]}
    }
    """

    private static let releaseCreateDecision = """
    {
      "action": "create_bottle",
      "proposedBottle": {
        "name": "Distillers Edition",
        "series": null,
        "category": "single_malt",
        "edition": "Feis Ile 2024",
        "statedAge": null,
        "abv": 54.2,
        "caskStrength": true,
        "singleCask": true,
        "maturation": null,
        "caskNumber": null,
        "outturn": null,
        "vintageYear": 2009,
        "releaseYear": 2024,
        "brand": {"id": 7, "name": "Lagavulin"},
        "distillers": [{"id": 12, "name": "Lagavulin"}, {"name": "Port Ellen"}],
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
          "pendingImage": \(pendingImage),
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

private actor ProgressLog {
    private(set) var events: [BottlePhotoProgress] = []

    func append(_ event: BottlePhotoProgress) {
        events.append(event)
    }
}
