@testable import Peated
import PeatedCore
import Testing

@MainActor
struct BottlePhotoResolutionViewModelTests {
    @Test
    func identifiesPhotoUsingDataUrl() async throws {
        let expected = BottlePhotoIdentification.stub
        let repository = BottlePhotoRepositoryStub(identification: expected)
        let viewModel = BottlePhotoResolutionViewModel(repository: repository)

        await viewModel.identify(imageData: Data([0x01, 0x02, 0x03]))

        #expect(viewModel.identification == expected)
        #expect(!viewModel.isIdentifying)
        #expect(viewModel.errorMessage == nil)
        let receivedRequest = await repository.identificationRequest()
        let request = try #require(receivedRequest)
        #expect(request.fileDataUrl == "data:image/jpeg;base64,AQID")
        #expect(!request.idempotencyKey.isEmpty)
    }

    @Test
    func retryReusesIdempotencyKeyForTheSamePhoto() async throws {
        let repository = BottlePhotoRepositoryStub(identification: .stub)
        let viewModel = BottlePhotoResolutionViewModel(repository: repository)

        await viewModel.identify(imageData: Data([0x01]))
        await viewModel.identify(imageData: Data([0x01]))

        let requests = await repository.identificationRequests()
        #expect(requests.count == 2)
        let firstRequest = try #require(requests.first)
        let lastRequest = try #require(requests.last)
        #expect(firstRequest.idempotencyKey == lastRequest.idempotencyKey)
    }

    @Test
    func createsApprovedPhotoProposal() async {
        let expectedBottle = Bottle.stub
        let repository = BottlePhotoRepositoryStub(
            identification: .stub,
            creation: BottlePhotoCreation(bottle: expectedBottle)
        )
        let viewModel = BottlePhotoResolutionViewModel(repository: repository)

        let creation = await viewModel.createBottle(createToken: "signed-create-token")

        #expect(creation?.bottle == expectedBottle)
        let receivedToken = await repository.creationToken()
        #expect(receivedToken == "signed-create-token")
        #expect(!viewModel.isCreating)
    }

    @Test
    func identificationFailureLeavesManualFallbackAvailable() async {
        let repository = BottlePhotoRepositoryStub(
            identification: .stub,
            error: APIError.timeout
        )
        let viewModel = BottlePhotoResolutionViewModel(repository: repository)

        await viewModel.identify(imageData: Data([0x01]))

        #expect(viewModel.identification == nil)
        #expect(viewModel.errorMessage?.contains("couldn't identify") == true)
        #expect(!viewModel.isIdentifying)
    }
}

private actor BottlePhotoRepositoryStub: BottlePhotoRepositoryProtocol {
    struct IdentificationRequest: Sendable {
        let fileDataUrl: String
        let idempotencyKey: String
    }

    private let identification: BottlePhotoIdentification
    private let creation: BottlePhotoCreation
    private let error: (any Error & Sendable)?
    private var receivedIdentificationRequests: [IdentificationRequest] = []
    private var receivedCreationToken: String?

    init(
        identification: BottlePhotoIdentification,
        creation: BottlePhotoCreation = BottlePhotoCreation(bottle: .stub),
        error: (any Error & Sendable)? = nil
    ) {
        self.identification = identification
        self.creation = creation
        self.error = error
    }

    func identifyBottlePhoto(
        fileDataUrl: String,
        idempotencyKey: String
    ) async throws -> BottlePhotoIdentification {
        receivedIdentificationRequests.append(IdentificationRequest(
            fileDataUrl: fileDataUrl,
            idempotencyKey: idempotencyKey
        ))
        if let error {
            throw error
        }
        return identification
    }

    func createBottleFromPhoto(createToken: String) async throws -> BottlePhotoCreation {
        receivedCreationToken = createToken
        if let error {
            throw error
        }
        return creation
    }

    func identificationRequest() -> IdentificationRequest? {
        receivedIdentificationRequests.last
    }

    func identificationRequests() -> [IdentificationRequest] {
        receivedIdentificationRequests
    }

    func creationToken() -> String? {
        receivedCreationToken
    }
}

private extension BottlePhotoIdentification {
    static let stub = BottlePhotoIdentification(
        pendingImageId: "pending-photo",
        pendingImageUrl: "https://example.com/pending.jpg",
        facts: [BottlePhotoFact(label: "Brand", value: "Ardbeg")],
        searchQuery: "Ardbeg Uigeadail",
        manualBottleInput: CreateBottleInput(name: "Uigeadail", brandName: "Ardbeg"),
        photoSuitabilityReason: nil,
        outcome: .matched(.stub)
    )
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
