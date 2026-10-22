import Foundation
import PeatedCore

@MainActor
final class BottlePhotoResolutionViewModel: ObservableObject {
    @Published private(set) var identification: BottlePhotoIdentification?
    @Published private(set) var isIdentifying = false
    @Published private(set) var isCreating = false
    @Published var errorMessage: String?
    /// What the server has reported so far while it identifies the photo.
    @Published private(set) var progress: [BottlePhotoProgress] = []

    private let repository: any BottlePhotoRepositoryProtocol
    private let idempotencyKey = UUID().uuidString
    private var identificationTask: Task<BottlePhotoIdentification, any Error>?

    /// One line naming the current step, matching the web resolver.
    var statusText: String {
        for event in progress.reversed() {
            switch event {
            case .step(.checkingPeated), .labelRead:
                return "Checking Peated…"
            case .step(.checkingWeb):
                return "Checking the web…"
            case .step(.comparing):
                return "Comparing details…"
            case .photo, .candidates:
                continue
            }
        }
        return "Reading the label…"
    }

    /// Bottles already in Peated that may match, shown before the lookup finishes.
    var likelyMatches: [Bottle] {
        for case let .candidates(bottles) in progress.reversed() {
            return bottles
        }
        return []
    }

    /// The stored photo. It arrives first, so an early pick can still attach it.
    var pendingImageId: String? {
        for case let .photo(pendingImageId) in progress {
            return pendingImageId
        }
        return nil
    }

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
        progress = []
        defer {
            isIdentifying = false
            identificationTask = nil
        }

        let repository = repository
        let fileDataUrl = "data:image/jpeg;base64,\(imageData.base64EncodedString())"
        let idempotencyKey = idempotencyKey
        // A separate task lets an early pick stop the lookup. Cancelling it closes
        // the stream, which stops the server's work.
        let task = Task {
            try await repository.identifyBottlePhoto(
                fileDataUrl: fileDataUrl,
                idempotencyKey: idempotencyKey,
                onProgress: { @MainActor [weak self] event in
                    self?.progress.append(event)
                }
            )
        }
        identificationTask = task

        do {
            identification = try await withTaskCancellationHandler {
                try await task.value
            } onCancel: {
                task.cancel()
            }
        } catch where task.isCancelled {
            // The member picked a likely match or left the screen.
        } catch {
            capture(error, operation: "identify", imageByteCount: imageData.count)
            errorMessage = "We couldn't identify that bottle. Please try again."
        }
    }

    /// Stops the lookup so the member can continue with a likely match.
    /// Returns the stored photo to attach, or nil when there is none yet.
    func pickLikelyMatch() -> String? {
        guard let pendingImageId else { return nil }

        identificationTask?.cancel()
        return pendingImageId
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
