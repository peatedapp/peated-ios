/// JSON bodies shaped like the Peated API contract in `PeatedAPI/Generated`.
///
/// Every required field of the generated schema is present; optional fields
/// appear only when a test asserts on them. A missing required field fails
/// decoding inside the app, which shows up as the screen's error state.
enum Fixtures {
    static let username = "tester"
    static let bottleName = "Uigeadail"
    static let bottleBrand = "Ardbeg"
    static let timestamp = "2026-09-01T12:00:00.000Z"

    static func user(id: Int = 1, username: String = Fixtures.username) -> String {
        "{\(userFields(id: id, username: username))}"
    }

    /// The `register` response: the new member plus a session token.
    static func auth(user: String = Fixtures.user()) -> String {
        #"{"user":\#(user),"accessToken":"ui-test-access-token"}"#
    }

    /// The `getUser` response: the member plus their counters.
    static func userProfile(id: Int = 1, username: String = Fixtures.username) -> String {
        #"""
        {\#(userFields(id: id, username: username)),
         "stats":{"tastings":0,"bottles":0,"collected":0,"contributions":0,
                  "library":{"total":0,"open":0,"sealed":0}}}
        """#
    }

    /// The error body the API sends for every refused request.
    static func serverError(status: Int, code: String, message: String) -> String {
        #"{"defined":true,"code":"\#(code)","status":\#(status),"message":"\#(message)","data":{}}"#
    }

    /// The 403 body the API sends when the member must accept updated terms.
    static let termsAcceptanceRequired = serverError(
        status: 403, code: "FORBIDDEN", message: "Terms acceptance required"
    )

    static func bottle(
        id: Int = 100,
        name: String = Fixtures.bottleName,
        brand: String = Fixtures.bottleBrand
    ) -> String {
        #"""
        {"id":\#(id),"peatedId":"bottle-\#(id)","fullName":"\#(brand) \#(name)","name":"\#(name)",
         "category":"single_malt",
         "brand":{"id":10,"peatedId":"brand-10","name":"\#(brand)","kind":"brand","totalTastings":0,
                  "publicReviewAndTastingCount":0,"totalBottles":1,"isFollowing":false,
                  "createdAt":"\#(timestamp)","updatedAt":"\#(timestamp)"},
         "memberScoreCount":0,"externalScoreCount":0,"raterCount":0,"scoreCount":0,
         "reviewScoreBandCounts":\#(bandCounts),"tastingBandCounts":\#(bandCounts),
         "totalTastings":0,"publicReviewAndTastingCount":0,"notedReviewAndTastingCount":0,
         "createdAt":"\#(timestamp)","updatedAt":"\#(timestamp)",
         "isFavorite":false,"isLibrary":false,"hasTasted":false}
        """#
    }

    static func tasting(
        id: Int = 500,
        bottle: String = Fixtures.bottle(),
        user: String = Fixtures.user(),
        ratingBand: String = "very_good"
    ) -> String {
        #"""
        {"id":\#(id),"bottle":\#(bottle),"ratingBand":"\#(ratingBand)","tags":[],
         "awards":[],"comments":0,"toasts":0,"hasToasted":false,
         "createdAt":"\#(timestamp)","createdBy":\#(user)}
        """#
    }

    /// A cursor page of any list operation.
    static func page(_ items: [String]) -> String {
        #"{"results":[\#(items.joined(separator: ","))],"rel":{},"total":\#(items.count)}"#
    }

    /// The `listActivity` response with one tasting session per tasting.
    static func activity(tastings: [String], user: String = Fixtures.user()) -> String {
        let sessions = tastings.enumerated().map { index, tasting in
            #"""
            {"id":"session-\#(index)","type":"tasting_session","priority":1,
             "startedAt":"\#(timestamp)","lastActivityAt":"\#(timestamp)",
             "createdBy":\#(user),"tastings":[\#(tasting)]}
            """#
        }
        return #"{"results":[\#(sessions.joined(separator: ","))],"rel":{}}"#
    }

    private static let bandCounts = #"{"mediocre":0,"good":0,"very_good":0,"outstanding":0,"unicorn":0}"#

    private static func userFields(id: Int, username: String) -> String {
        #"""
        "id":\#(id),"username":"\#(username)","email":"\#(username)@example.com",
         "verified":true,"admin":false,"mod":false,"createdAt":"\#(timestamp)"
        """#
    }
}
