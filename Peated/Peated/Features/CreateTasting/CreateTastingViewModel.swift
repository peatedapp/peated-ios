import Foundation
import PeatedCore

#if canImport(UIKit)
    import UIKit
#endif

@MainActor
class CreateTastingViewModel: ObservableObject {
    // Step 1: Bottle
    @Published var selectedBottle: Bottle?
    @Published var pendingBottlePhotoId: String?
    @Published var bottleSearchText = ""
    @Published var searchResults: [Bottle] = []
    @Published var isSearching = false
    @Published var recentBottles: [Bottle] = []

    // Step 2: Rating & Notes
    @Published var ratingBand: TastingRatingBand?
    @Published var notes = ""
    @Published var selectedTags: Set<String> = []
    @Published private(set) var suggestedTags: [TastingTag] = []
    @Published private(set) var isLoadingSuggestedTags = false
    @Published private(set) var suggestedTagsError: String?
    @Published var servingStyle: ServingStyle?
    @Published var color: Int?

    // Step 3: Location
    @Published var selectedLocation: Location?
    @Published var isDrinkingAtHome = false
    @Published var taggedFriends: [User] = []

    // Step 4: Photos
    @Published var photos: [UIImage] = []
    @Published var uploadedPhotoIds: [String] = []

    // State
    @Published var isSubmitting = false
    @Published var submissionSuccessful = false
    @Published var showingError = false
    @Published var errorMessage = ""
    @Published var showingCancelAlert = false

    var hasUnsavedChanges: Bool {
        selectedBottle != nil ||
            pendingBottlePhotoId != nil ||
            ratingBand != nil ||
            !notes.isEmpty ||
            !selectedTags.isEmpty ||
            !photos.isEmpty
    }

    private let tastingRepository: TastingRepository
    private let bottleRepository: any BottleRepositoryProtocol
    private let imageUploadService: ImageUploadService

    init(
        tastingRepository: TastingRepository? = nil,
        bottleRepository: (any BottleRepositoryProtocol)? = nil,
        imageUploadService: ImageUploadService? = nil
    ) {
        // Use shared API client to ensure proper request handling
        let apiClient = APIClient.shared
        self.tastingRepository = tastingRepository ?? TastingRepository(apiClient: apiClient)
        self.bottleRepository = bottleRepository ?? BottleRepository(apiClient: apiClient)
        self.imageUploadService = imageUploadService ?? ImageUploadService(apiClient: apiClient)
    }

    func submitTasting() async {
        isSubmitting = true
        showingError = false

        do {
            // Create tasting first
            let input = CreateTastingInput(
                bottleId: selectedBottle!.id,
                ratingBand: ratingBand,
                notes: notes.isEmpty ? nil : notes,
                servingStyle: servingStyle?.rawValue,
                tags: selectedTags.sorted(),
                location: selectedLocation?.name,
                color: color,
                pendingImageId: pendingBottlePhotoId
            )

            let tasting = try await tastingRepository.createTasting(input)

            // Upload photo as part of the tasting (only support one photo for now)
            if let firstPhoto = photos.first {
                // Convert UIImage to compressed data
                if let imageData = firstPhoto.compressedForUpload(maxSizeKB: 1024) {
                    do {
                        // Upload the image to the created tasting
                        let imageUrl = try await imageUploadService.uploadTastingImage(
                            tastingId: tasting.id,
                            image: imageData
                        )
                        uploadedPhotoIds = [imageUrl]
                        print("Successfully uploaded photo: \(imageUrl)")
                    } catch {
                        // Don't fail the entire submission if photo upload fails
                        print("Failed to upload photo: \(error)")
                    }
                }
            }

            submissionSuccessful = true
        } catch {
            // Log detailed error information for debugging
            print("CreateTastingViewModel: Failed to submit tasting - \(error)")
            if let apiError = error as? APIError {
                print("CreateTastingViewModel: API Error type: \(apiError)")
            }

            errorMessage = error.localizedDescription
            showingError = true
        }

        isSubmitting = false
    }

    func loadSuggestedTags() async {
        guard let bottle = selectedBottle else {
            suggestedTags = []
            suggestedTagsError = nil
            isLoadingSuggestedTags = false
            return
        }

        let bottleId = bottle.id
        suggestedTags = bottle.suggestedTags.map {
            TastingTag(name: $0, category: "suggested")
        }
        isLoadingSuggestedTags = true
        suggestedTagsError = nil

        do {
            let tags = try await bottleRepository.getSuggestedTags(bottleId: bottleId)
            guard selectedBottle?.id == bottleId else { return }
            suggestedTags = tags
        } catch {
            guard selectedBottle?.id == bottleId else { return }
            suggestedTags = bottle.suggestedTags.map {
                TastingTag(name: $0, category: "suggested")
            }
            suggestedTagsError = suggestedTags.isEmpty
                ? "Notes are unavailable right now. Try again in a moment."
                : nil
        }

        if selectedBottle?.id == bottleId {
            isLoadingSuggestedTags = false
        }
    }

    func searchBottles(query: String) async {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true
        defer { isSearching = false }

        do {
            searchResults = try await bottleRepository.searchBottles(query: query, limit: 20)
        } catch is CancellationError {
            return
        } catch {
            searchResults = []
            errorMessage = "We couldn't search for bottles. \(error.localizedDescription)"
            showingError = true
        }
    }

    func bottleForBarcode(_ barcode: String) async -> Bottle? {
        isSearching = true
        defer { isSearching = false }

        do {
            return try await bottleRepository.getBottle(barcode: barcode)
        } catch APIError.notFound {
            errorMessage = "No bottle is linked to that barcode yet. Search by name or add it manually."
            showingError = true
            return nil
        } catch {
            errorMessage = "We couldn't look up that barcode. \(error.localizedDescription)"
            showingError = true
            return nil
        }
    }

    func loadRecentBottles() async {
        // TODO: Implement fetching user's recent bottles from their tasting history
        // For now, leave empty - users should use search to find bottles
        recentBottles = []
    }
}

// MARK: - Supporting Types

public enum ServingStyle: String, CaseIterable {
    case neat
    case rocks
    case water

    public var displayName: String {
        switch self {
        case .neat: "Neat"
        case .rocks: "On the Rocks"
        case .water: "With Water"
        }
    }
}

/// Temporary placeholder types until we have the actual models
public struct Location: Identifiable {
    public let id: String
    public let name: String
    public let address: String?

    public init(id: String, name: String, address: String? = nil) {
        self.id = id
        self.name = name
        self.address = address
    }
}

// User type is already defined in PeatedCore
