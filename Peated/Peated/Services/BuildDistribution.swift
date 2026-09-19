import Foundation

/// How this build reached the device. Drives the Sentry environment so debug
/// and TestFlight traffic stays separate from App Store users.
enum BuildDistribution: Equatable {
    case development
    case testFlight
    case appStore

    static var current: BuildDistribution {
        #if DEBUG
            return .development
        #else
            // TestFlight installs carry a sandbox receipt; App Store installs do not.
            return BuildDistribution(receiptName: Bundle.main.appStoreReceiptURL?.lastPathComponent)
        #endif
    }

    init(receiptName: String?) {
        self = receiptName == "sandboxReceipt" ? .testFlight : .appStore
    }

    var sentryEnvironment: String {
        switch self {
        case .development: "development"
        case .testFlight: "testflight"
        case .appStore: "production"
        }
    }
}
