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
    
    init(tastingRepository: TastingRepository? = nil, bottleRepository: BottleRepository? = nil) {
        // Create shared API client
        let apiClient = APIClient(
            serverURL: URL(string: "https://api.peated.com/v1")!
        )
        self.tastingRepository = tastingRepository ?? TastingRepository(apiClient: apiClient)
        self.bottleRepository = bottleRepository ?? BottleRepository(apiClient: apiClient)
        
        // DEBUG: Add test bottle to bypass search issue
        #if DEBUG
        self.selectedBottle = Bottle(
            id: "test-123",
            name: "Lagavulin 16-year-old",
            fullName: "Lagavulin 16-year-old",
            brand: Brand(id: "1", name: "Lagavulin"),
            category: "Single Malt",
            caskStrength: false,
            singleCask: false,
            statedAge: 16,
            imageUrl: nil,
            abv: 43.0,
            avgRating: 4.5,
            totalRatings: 100
        )
        #endif
    }
    
    func submitTasting() async {
        isSubmitting = true
        showingError = false
        
        do {
            // Upload photos first
            if !photos.isEmpty {
                uploadedPhotoIds = try await uploadPhotos()
            }
            
            // Create tasting using PeatedCore's CreateTastingInput
            let input = CreateTastingInput(
                bottleId: selectedBottle!.id,
                rating: rating,
                notes: notes.isEmpty ? nil : notes,
                servingStyle: servingStyle?.rawValue,
                tags: Array(selectedTags),
                location: selectedLocation?.name
            )
            
            let tasting = try await tastingRepository.createTasting(input)
            
            // Post to social media if requested
            if postToFacebook || postToTwitter {
                await postToSocialMedia(tasting)
            }
            
            submissionSuccessful = true
        } catch {
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
        // TODO: Implement fetching user's recent bottles
        // For now, we'll leave this empty
        recentBottles = []
    }
    
    private func uploadPhotos() async throws -> [String] {
        // TODO: Implementation for photo upload
        return []
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