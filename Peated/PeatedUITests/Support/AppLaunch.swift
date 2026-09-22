import XCTest

/// Which session the app starts in. The app's harness clears the keychain
/// first, so a test never inherits a token from an earlier run.
enum Session: String {
    case signedOut
    case signedIn
}

/// Launches the app in the state a test asked for.
///
/// This is the test half of the contract in `Peated/App/UITestHarness.swift`:
/// the same launch argument and environment keys, sent from the test process.
@MainActor
enum AppLaunch {
    static let argument = "--ui-testing"
    static let sessionKey = "PEATED_UI_TEST_SESSION"
    static let stubsKey = "PEATED_UI_TEST_STUBS"

    /// Configures an app for launch without launching it. The harness reads
    /// the launch environment once at startup, so the same app must be
    /// terminated and relaunched to change it.
    static func configure(
        session: Session,
        stubs: [APIStub],
        resetting resources: [XCUIProtectedResource] = []
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += [argument]
        app.launchEnvironment[sessionKey] = session.rawValue
        app.launchEnvironment[stubsKey] = stubs.launchEnvironmentValue()
        for resource in resources {
            app.resetAuthorizationStatus(for: resource)
        }
        return app
    }

    static func launch(
        session: Session,
        stubs: [APIStub],
        resetting resources: [XCUIProtectedResource] = []
    ) -> XCUIApplication {
        let app = configure(session: session, stubs: stubs, resetting: resources)
        app.launch()
        return app
    }
}
