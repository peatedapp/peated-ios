import Foundation
import XCTest

/// One canned API answer, sent to the app through the launch environment.
struct StubResponse {
    let status: Int
    let json: String

    static func ok(_ json: String) -> StubResponse {
        StubResponse(status: 200, json: json)
    }

    static func failure(_ status: Int, _ json: String) -> StubResponse {
        StubResponse(status: status, json: json)
    }
}

/// The responses one generated API operation returns, in order. The last
/// response repeats, so `[failure, ok]` means "fail once, then succeed".
///
/// The app decodes this table in `Peated/App/UITestHarness.swift`. When the
/// same operation appears twice in a launch, the later entry wins.
struct APIStub {
    let operation: String
    let responses: [StubResponse]

    static func ok(_ operation: String, _ json: String) -> APIStub {
        APIStub(operation: operation, responses: [.ok(json)])
    }

    static func failure(_ operation: String, _ status: Int, _ json: String) -> APIStub {
        APIStub(operation: operation, responses: [.failure(status, json)])
    }

    static func sequence(_ operation: String, _ responses: [StubResponse]) -> APIStub {
        APIStub(operation: operation, responses: responses)
    }
}

extension [APIStub] {
    /// What a signed-in member needs to reach the Activity tab: their profile,
    /// an empty feed, and no notifications.
    static func signedInBaseline() -> [APIStub] {
        [
            .ok("getMe", #"{"user":\#(Fixtures.user())}"#),
            .ok("getUser", Fixtures.userProfile()),
            .ok("listActivity", Fixtures.activity(tastings: [])),
            .ok("countNotifications", #"{"count":0}"#)
        ]
    }

    /// What the Add Tasting flow needs once a member is signed in.
    static func createTasting(bottle: String = Fixtures.bottle(), user: String = Fixtures.user()) -> [APIStub] {
        let tasting = Fixtures.tasting(bottle: bottle, user: user)
        return [
            .ok("listBottles", Fixtures.page([bottle])),
            .ok("getBottleSuggestedTags", #"{"results":[]}"#),
            .ok("listTags", Fixtures.page([])),
            .ok("createTasting", #"{"tasting":\#(tasting),"awards":[]}"#)
        ]
    }

    /// The JSON the app's launch harness decodes.
    func launchEnvironmentValue(file: StaticString = #filePath, line: UInt = #line) -> String {
        let entries: [[String: Any]] = map { stub in
            [
                "operation": stub.operation,
                "responses": stub.responses.map { response -> [String: Any] in
                    var entry: [String: Any] = ["status": response.status]
                    do {
                        entry["body"] = try JSONSerialization.jsonObject(with: Data(response.json.utf8))
                    } catch {
                        XCTFail("Stub for \(stub.operation) is not valid JSON: \(error)", file: file, line: line)
                    }
                    return entry
                }
            ]
        }
        guard let data = try? JSONSerialization.data(withJSONObject: entries),
              let value = String(data: data, encoding: .utf8)
        else {
            XCTFail("Could not encode API stubs", file: file, line: line)
            return "[]"
        }
        return value
    }
}
