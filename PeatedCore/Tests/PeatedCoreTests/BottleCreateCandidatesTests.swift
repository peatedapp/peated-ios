import Foundation
import HTTPTypes
import OpenAPIRuntime
@testable import PeatedCore
import Testing

struct BottleCreateCandidatesTests {
    @Test
    func sendsDraftIdentityAndReleaseFacts() async throws {
        let transport =
            RecordingTransport(response: #"{"results": [], "rel": {"nextCursor": null, "prevCursor": null}}"#)
        let repository = BottleRepository(apiClient: APIClient(transport: transport))

        _ = try await repository.findCreateCandidates(CreateBottleInput(
            name: "Uigeadail",
            brandName: "Ardbeg",
            category: .singleMalt,
            statedAge: 10,
            abv: 54.2,
            edition: "Batch 24",
            distillers: [.existing(id: 42, name: "Ardbeg"), .new(name: "Caol Ila")],
            singleCask: true,
            caskStrength: true,
            vintageYear: 2009,
            releaseYear: 2024
        ))

        let query = try #require(transport.queryItems)
        #expect(query["name"] == "Uigeadail")
        #expect(query["brand[name]"] == "Ardbeg")
        #expect(query["category"] == "single_malt")
        #expect(query["statedAge"] == "10.0")
        #expect(query["abv"] == "54.2")
        #expect(query["edition"] == "Batch 24")
        #expect(query["singleCask"] == "true")
        #expect(query["caskStrength"] == "true")
        #expect(query["vintageYear"] == "2009.0")
        #expect(query["releaseYear"] == "2024.0")
        #expect(query["limit"] == "3")
        #expect(query["noAgeStatement"] == nil)
        #expect(!query.keys.contains { $0.hasPrefix("distillers") })
    }

    @Test
    func leavesUnstatedFactsUnset() async throws {
        let transport =
            RecordingTransport(response: #"{"results": [], "rel": {"nextCursor": null, "prevCursor": null}}"#)
        let repository = BottleRepository(apiClient: APIClient(transport: transport))

        _ = try await repository.findCreateCandidates(CreateBottleInput(
            name: "Uigeadail",
            brandName: "Ardbeg",
            statedAge: 10,
            noAgeStatement: true
        ))

        let query = try #require(transport.queryItems)
        #expect(query["noAgeStatement"] == "true")
        #expect(query["statedAge"] == nil)
        #expect(query["singleCask"] == nil)
        #expect(query["caskStrength"] == nil)
        #expect(query["category"] == nil)
        #expect(query["abv"] == nil)
    }

    @Test
    func mapsResultsToBottles() async throws {
        let transport =
            RecordingTransport(
                response: #"{"results": [\#(Self.bottle)], "rel": {"nextCursor": null, "prevCursor": null}}"#
            )
        let repository = BottleRepository(apiClient: APIClient(transport: transport))

        let candidates = try await repository.findCreateCandidates(CreateBottleInput(
            name: "Distillers Edition",
            brandName: "Lagavulin"
        ))

        let bottle = try #require(candidates.first)
        #expect(candidates.count == 1)
        #expect(bottle.id == "42")
        #expect(bottle.fullName == "Lagavulin Distillers Edition")
        #expect(bottle.brand.name == "Lagavulin")
        #expect(bottle.category == "single_malt")
        #expect(bottle.abv == 43)
    }

    private static let bottle = """
    {
      "id": 42,
      "peatedId": "B0042",
      "fullName": "Lagavulin Distillers Edition",
      "name": "Distillers Edition",
      "category": "single_malt",
      "abv": 43,
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
      "hasTasted": false,
      "comparison": {"agreements": ["brand"], "missing": [], "conflicts": []}
    }
    """
}

/// Records the last request's query and answers every call with one JSON body.
private final class RecordingTransport: ClientTransport, @unchecked Sendable {
    private let lock = NSLock()
    private let response: String
    private var recordedQuery: [String: String]?

    init(response: String) {
        self.response = response
    }

    var queryItems: [String: String]? {
        lock.withLock { recordedQuery }
    }

    func send(
        _ request: HTTPRequest,
        body _: HTTPBody?,
        baseURL _: URL,
        operationID _: String
    ) async throws -> (HTTPResponse, HTTPBody?) {
        let items = URLComponents(string: request.path ?? "")?.queryItems ?? []
        lock.withLock {
            recordedQuery = Dictionary(
                items.map { ($0.name, $0.value ?? "") },
                uniquingKeysWith: { first, _ in first }
            )
        }
        var head = HTTPResponse(status: .ok)
        head.headerFields[.contentType] = "application/json"
        return (head, HTTPBody(Data(response.utf8)))
    }
}
