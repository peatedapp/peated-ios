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
        // Create shared API client
        let apiClient = APIClient(
            serverURL: URL(string: "https://api.peated.com/v1")!
        )
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
            
            // Upload photos after tasting is created
            if !photos.isEmpty {
                // Convert UIImages to compressed data
                let imageDataArray = photos.compactMap { image in
                    image.compressedForUpload(maxSizeKB: 1024)
                }
                
                if !imageDataArray.isEmpty {
                    // Upload images to the created tasting
                    let uploadedUrls = try await imageUploadService.uploadTastingImages(
                        tastingId: tasting.id,
                        images: imageDataArray
                    )
                    uploadedPhotoIds = uploadedUrls
                    
                    print("Successfully uploaded \(uploadedUrls.count) photos")
                }
            }
            
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
        // Get the authenticated user's recent tastings
        // and extract unique bottles from them
        
        // For now, let's simulate with some mock data
        // In a real implementation, this would fetch from the user's tasting history
        
        // Mock implementation - replace with actual API call
        DispatchQueue.main.async { [weak self] in
            self?.recentBottles = [
                Bottle(
                    id: "recent-1",
                    name: "Ardbeg 10",
                    fullName: "Ardbeg 10 Year Old",
                    brand: Brand(id: "ardbeg", name: "Ardbeg"),
                    category: "Single Malt",
                    caskStrength: false,
                    singleCask: false,
                    statedAge: 10,
                    imageUrl: nil,
                    abv: 46.0,
                    avgRating: 4.3,
                    totalRatings: 1250
                ),
                Bottle(
                    id: "recent-2",
                    name: "Highland Park 12",
                    fullName: "Highland Park 12 Year Old",
                    brand: Brand(id: "hp", name: "Highland Park"),
                    category: "Single Malt",
                    caskStrength: false,
                    singleCask: false,
                    statedAge: 12,
                    imageUrl: nil,
                    abv: 40.0,
                    avgRating: 4.1,
                    totalRatings: 890
                ),
                Bottle(
                    id: "recent-3",
                    name: "Glenfiddich 15",
                    fullName: "Glenfiddich 15 Year Old Solera",
                    brand: Brand(id: "glenfiddich", name: "Glenfiddich"),
                    category: "Single Malt",
                    caskStrength: false,
                    singleCask: false,
                    statedAge: 15,
                    imageUrl: nil,
                    abv: 40.0,
                    avgRating: 4.0,
                    totalRatings: 2100
                )
            ]
        }
        
        // TODO: When API is ready, implement like this:
        // do {
        //     let userTastings = try await tastingRepository.getUserTastings(limit: 10)
        //     let uniqueBottles = Dictionary(grouping: userTastings, by: { $0.bottleId })
        //         .compactMap { $0.value.first }
        //         .map { tasting in
        //             Bottle(
        //                 id: tasting.bottleId,
        //                 name: tasting.bottleName,
        //                 fullName: tasting.bottleName,
        //                 brand: Brand(id: "", name: tasting.bottleBrandName),
        //                 category: tasting.bottleCategory,
        //                 // ... other properties
        //             )
        //         }
        //     recentBottles = Array(uniqueBottles.prefix(5))
        // } catch {
        //     print("Failed to load recent bottles: \(error)")
        //     recentBottles = []
        // }
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