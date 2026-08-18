import Foundation
import PeatedCore

@MainActor
final class BottlePhotoResolutionViewModel: ObservableObject {
    @Published private(set) var identification: BottlePhotoIdentification?
    @Published private(set) var isIdentifying = false
    @Published private(set) var isCreating = false
    @Published var errorMessage: String?

    private let repository: any BottlePhotoRepositoryProtocol
    private let idempotencyKey = UUID().uuidString

    init(
        repository: any BottlePhotoRepositoryProtocol =
            BottlePhotoIdentificationRepository()
    ) {
        self.repository = repository
    }

    func identify(imageData: Data) async {
        guard !isIdentifying else { return }

        isIdentifying = true
        identification = nil
        errorMessage = nil
        defer { isIdentifying = false }

        do {
            identification = try await repository.identifyBottlePhoto(
                fileDataUrl: "data:image/jpeg;base64,\(imageData.base64EncodedString())",
                idempotencyKey: idempotencyKey
            )
        } catch {
            errorMessage = "We couldn't identify that bottle. \(error.localizedDescription)"
        }
    }

    func createBottle(createToken: String) async -> BottlePhotoCreation? {
        guard !isCreating else { return nil }

        isCreating = true
        errorMessage = nil
        defer { isCreating = false }

        do {
            return try await repository.createBottleFromPhoto(createToken: createToken)
        } catch {
            errorMessage = "We couldn't create that bottle. \(error.localizedDescription)"
            return nil
        }
    }
}
