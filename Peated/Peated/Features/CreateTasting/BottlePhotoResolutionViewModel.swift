import Foundation
import PeatedCore
import Sentry

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
        SentrySDK.capture(error: error) { scope in
            scope.setTag(value: "bottle_photo", key: "feature")
            scope.setTag(value: operation, key: "bottle_photo.operation")
            scope.setTag(value: Self.errorKind(error), key: "bottle_photo.error_kind")
            if let imageByteCount {
                scope.setExtra(value: imageByteCount, key: "bottle_photo.image_byte_count")
            }
        }
    }

    private static func errorKind(_ error: any Error) -> String {
        guard let apiError = error as? APIError else {
            return String(describing: type(of: error))
        }

        return switch apiError {
        case .invalidResponse, .decodingError:
            "invalid_response"
        case .requestFailed:
            "request_failed"
        case let .unexpectedResponse(statusCode):
            "http_\(statusCode)"
        case .unauthorized:
            "unauthorized"
        case .notFound:
            "not_found"
        case let .serverError(statusCode, _):
            "http_\(statusCode)"
        case .networkError, .timeout:
            "network"
        case .notImplemented:
            "not_implemented"
        case .termsAcceptanceRequired:
            "terms_acceptance_required"
        }
    }
}
