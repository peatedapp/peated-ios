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
            capture(error, operation: "identify", imageByteCount: imageData.count)
            errorMessage = "We couldn't identify that bottle. Please try again."
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
            capture(error, operation: "create")
            errorMessage = "We couldn't create that bottle. Please try again."
            return nil
        }
    }

    private func capture(
        _ error: any Error,
        operation: String,
        imageByteCount: Int? = nil
    ) {
        var attributes: [String: TelemetryAttribute] = [:]
        if let imageByteCount {
            attributes["image_byte_count"] = .int(imageByteCount)
        }
        Telemetry.capture(error, feature: "bottle_photo", operation: operation, attributes: attributes)
    }
}
