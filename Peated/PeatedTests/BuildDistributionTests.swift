@testable import Peated
import Testing

struct BuildDistributionTests {
    @Test
    func sandboxReceiptMeansTestFlight() {
        let distribution = BuildDistribution(receiptName: "sandboxReceipt")

        #expect(distribution == .testFlight)
        #expect(distribution.sentryEnvironment == "testflight")
    }

    @Test
    func otherReceiptsMeanAppStore() {
        #expect(BuildDistribution(receiptName: "receipt") == .appStore)
        #expect(BuildDistribution(receiptName: nil) == .appStore)
        #expect(BuildDistribution(receiptName: nil).sentryEnvironment == "production")
    }

    @Test
    func developmentBuildsReportDevelopment() {
        #expect(BuildDistribution.development.sentryEnvironment == "development")
    }
}
