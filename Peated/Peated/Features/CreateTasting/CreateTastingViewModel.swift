import Foundation
import PeatedCore

#if canImport(UIKit)
import UIKit
#endif

@MainActor
class CreateTastingViewModel: ObservableObject {
    // Step 1: Bottle
    @Published var selectedBottle: Bottle?
    @Published var bottleSearchText = ""
    @Published var searchResults: [Bottle] = []
    @Published var isSearching = false
    @Published var recentBottles: [Bottle] = []
    
    // Step 2: Rating & Notes
    @Published var rating: Double = 0
    @Published var notes = ""
    @Published var selectedTags: Set<String> = []
    @Published var servingStyle: ServingStyle?
    @Published var color: Int? = nil
    
    // Step 3: Location
    @Published var selectedLocation: Location?
    @Published var isDrinkingAtHome = false
    @Published var taggedFriends: [User] = []
    
    // Step 4: Photos
    @Published var photos: [UIImage] = []
    @Published var uploadedPhotoIds: [String] = []
    
    // Step 5: Confirmation
    @Published var isPublic = true
    @Published var postToFacebook = false
    @Published var postToTwitter = false
    
    // State
    @Published var isSubmitting = false
    @Published var submissionSuccessful = false
    @Published var showingError = false
    @Published var errorMessage = ""
    @Published var showingCancelAlert = false
    
    var hasUnsavedChanges: Bool {
        selectedBottle != nil || 
        rating != 0 || 
        !notes.isEmpty || 
        !photos.isEmpty
    }
    
    private let tastingRepository: TastingRepository
    private let bottleRepository: BottleRepository
    private let imageUploadService: ImageUploadService
    
    init(
        tastingRepository: TastingRepository? = nil,
        bottleRepository: BottleRepository? = nil,
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
                rating: rating,
                notes: notes.isEmpty ? nil : notes,
                servingStyle: servingStyle?.rawValue,
                tags: Array(selectedTags),
                location: selectedLocation?.name,
                color: color
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
            
            // Post to social media if requested
            if postToFacebook || postToTwitter {
                await postToSocialMedia(tasting)
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
    
    func searchBottles(query: String) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        do {
            searchResults = try await bottleRepository.searchBottles(query: query, limit: 20)
        } catch {
            // Silently fail search, just show no results
            searchResults = []
        }
        
        isSearching = false
    }
    
    func loadRecentBottles() async {
        // TODO: Implement fetching user's recent bottles from their tasting history
        // For now, leave empty - users should use search to find bottles
        recentBottles = []
    }
    
    private func postToSocialMedia(_ tasting: TastingFeedItem) async {
        // TODO: Implementation for social sharing
    }
}

// MARK: - Supporting Types

public enum ServingStyle: String, CaseIterable {
    case neat = "neat"
    case rocks = "rocks" 
    case water = "water"
    
    public var displayName: String {
        switch self {
        case .neat: return "Neat"
        case .rocks: return "On the Rocks"
        case .water: return "With Water"
        }
    }
}

// Temporary placeholder types until we have the actual models
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