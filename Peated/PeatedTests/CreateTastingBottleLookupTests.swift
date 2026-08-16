@testable import Peated
import PeatedCore
import Testing

@MainActor
struct CreateTastingBottleLookupTests {
    @Test
    func barcodeLookupReturnsExactBottle() async {
        let expected = Bottle.stub
        let viewModel = CreateTastingViewModel(
            bottleRepository: BottleRepositoryStub(barcodeResult: .bottle(expected))
        )

        let bottle = await viewModel.bottleForBarcode("4006381333931")

        #expect(bottle == expected)
        #expect(!viewModel.showingError)
        #expect(!viewModel.isSearching)
    }

    @Test
    func unknownBarcodeExplainsTheFallback() async {
        let viewModel = CreateTastingViewModel(
            bottleRepository: BottleRepositoryStub(barcodeResult: .notFound)
        )

        let bottle = await viewModel.bottleForBarcode("4006381333931")

        #expect(bottle == nil)
        #expect(viewModel.showingError)
        #expect(viewModel.errorMessage.contains("Search by name or add it manually"))
        #expect(!viewModel.isSearching)
    }

    @Test
    func searchFailureIsNotPresentedAsNoResults() async {
        let viewModel = CreateTastingViewModel(
            bottleRepository: BottleRepositoryStub(searchFails: true)
        )

        await viewModel.searchBottles(query: "Ardbeg")

        #expect(viewModel.searchResults.isEmpty)
        #expect(viewModel.showingError)
        #expect(viewModel.errorMessage.contains("couldn't search"))
        #expect(!viewModel.isSearching)
    }
}

private actor BottleRepositoryStub: BottleRepositoryProtocol {
    enum BarcodeResult: Sendable {
        case bottle(Bottle)
        case notFound
    }

    private let barcodeResult: BarcodeResult
    private let searchFails: Bool

    init(barcodeResult: BarcodeResult = .notFound, searchFails: Bool = false) {
        self.barcodeResult = barcodeResult
        self.searchFails = searchFails
    }

    func searchBottles(query _: String, limit _: Int) async throws -> [Bottle] {
        if searchFails {
            throw APIError.timeout
        }
        return []
    }

    func createBottle(_: CreateBottleInput) async throws -> Bottle {
        Bottle.stub
    }

    func getBottle(barcode _: String) async throws -> Bottle {
        switch barcodeResult {
        case let .bottle(bottle): bottle
        case .notFound: throw APIError.notFound
        }
    }

    func getBottle(id _: String) async throws -> Bottle {
        Bottle.stub
    }

    func getPopularBottles(limit _: Int) async throws -> [Bottle] {
        []
    }

    func getTopRatedBottles(limit _: Int) async throws -> [Bottle] {
        []
    }

    func getEntityBottles(entityId _: String) async throws -> [Bottle] {
        []
    }

    func getSuggestedTags(bottleId _: String) async throws -> [TastingTag] {
        []
    }
}

private extension Bottle {
    static let stub = Bottle(
        id: "42",
        name: "Uigeadail",
        fullName: "Ardbeg Uigeadail",
        brand: Brand(id: "7", name: "Ardbeg"),
        category: BottleCategory.singleMalt.rawValue,
        abv: 54.2
    )
}
