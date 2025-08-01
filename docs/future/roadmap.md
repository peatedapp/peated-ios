# Future Roadmap & Enhancements

## Overview

This document outlines potential future features and enhancements for the Peated iOS app based on competitive analysis and user needs. These features are organized by priority and complexity to guide post-launch development.

## Quick-Add Features

### Barcode Scanning
**Priority**: High  
**Complexity**: Medium  
**Timeline**: v1.2

Implement bottle recognition via barcode scanning for faster check-ins:

```swift
struct BarcodeScannerView: View {
    @StateObject private var scanner = BarcodeScanner()
    @Binding var scannedBottle: Bottle?
    
    var body: some View {
        DataScannerViewController(
            recognizedDataTypes: [.barcode()],
            qualityLevel: .accurate,
            isHighlightingEnabled: true
        )
        .onRecognizedItem { item in
            if case .barcode(let barcode) = item {
                Task {
                    scannedBottle = await lookupBottle(barcode: barcode.payloadStringValue)
                }
            }
        }
    }
}
```

**Features**:
- UPC/EAN barcode recognition
- Quick add to collection
- Auto-fill bottle details
- Fallback to manual search

### Quick Rating Mode
**Priority**: High  
**Complexity**: Low  
**Timeline**: v1.1

Allow users to quickly rate without full tasting flow:

```swift
struct QuickRatingSheet: View {
    let bottle: Bottle
    @State private var rating: Double = 0
    @State private var notes: String = ""
    
    var body: some View {
        VStack(spacing: 24) {
            // Bottle header
            BottleHeader(bottle: bottle)
            
            // Quick rating
            StarRatingInput(rating: $rating, size: 40)
            
            // Optional quick note
            TextField("Quick note (optional)", text: $notes)
                .textFieldStyle(.roundedBorder)
            
            // Actions
            HStack {
                Button("Cancel") { dismiss() }
                Button("Save") { saveQuickRating() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}
```

### Voice Notes
**Priority**: Medium  
**Complexity**: Medium  
**Timeline**: v1.3

Audio recordings for tasting notes:

```swift
struct VoiceNoteRecorder: View {
    @StateObject private var audioRecorder = AudioRecorder()
    @State private var isRecording = false
    
    var body: some View {
        VStack {
            // Waveform visualization
            AudioWaveformView(samples: audioRecorder.samples)
                .frame(height: 100)
            
            // Recording controls
            Button(action: toggleRecording) {
                Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(isRecording ? .red : .accentColor)
            }
            
            // Transcription option
            if audioRecorder.hasRecording {
                Button("Transcribe to Text") {
                    Task {
                        await transcribeAudio()
                    }
                }
            }
        }
    }
}
```

## Discovery Enhancements

### AI-Powered Recommendations
**Priority**: High  
**Complexity**: High  
**Timeline**: v2.0

Machine learning based recommendations:

```swift
struct RecommendationEngine {
    func getRecommendations(for user: User) async -> [Recommendation] {
        // Analyze user's tasting history
        let tastingProfile = analyzeTastingPreferences(user.tastings)
        
        // Find similar bottles based on:
        // - Flavor profiles
        // - Rating patterns
        // - Category preferences
        // - Price range
        
        return await generateRecommendations(
            profile: tastingProfile,
            excludeOwned: true,
            limit: 20
        )
    }
}

struct RecommendationCard: View {
    let recommendation: Recommendation
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Because you liked \(recommendation.basedOn)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            BottleRow(bottle: recommendation.bottle)
            
            Text("Why: \(recommendation.reason)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
```

### Flavor Profile Matching
**Priority**: High  
**Complexity**: Medium  
**Timeline**: v1.4

Advanced flavor search and matching:

```swift
struct FlavorProfileSearch: View {
    @State private var selectedFlavors: Set<FlavorTag> = []
    @State private var flavorIntensity: [FlavorTag: Double] = [:]
    
    var body: some View {
        VStack {
            // Flavor wheel selector
            FlavorWheelView(
                selectedFlavors: $selectedFlavors,
                onIntensityChange: { tag, intensity in
                    flavorIntensity[tag] = intensity
                }
            )
            
            // Match results
            List(matchingBottles) { bottle in
                HStack {
                    BottleRow(bottle: bottle)
                    Spacer()
                    Text("\(bottle.flavorMatchScore)% match")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
```

### Similar Bottles
**Priority**: Medium  
**Complexity**: Medium  
**Timeline**: v1.3

"Bottles like this" feature:

```swift
extension BottleDetailView {
    var similarBottlesSection: some View {
        VStack(alignment: .leading) {
            Text("Similar Bottles")
                .font(.headline)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(bottle.similarBottles) { similar in
                        SimilarBottleCard(
                            bottle: similar.bottle,
                            similarity: similar.score,
                            commonTraits: similar.commonTraits
                        )
                    }
                }
            }
        }
    }
}
```

## Community Features

### Local Whisky Groups
**Priority**: Medium  
**Complexity**: High  
**Timeline**: v2.0

Geographic and interest-based communities:

```swift
struct WhiskyGroups: View {
    @State private var nearbyGroups: [WhiskyGroup] = []
    @State private var joinedGroups: [WhiskyGroup] = []
    
    var body: some View {
        List {
            Section("Your Groups") {
                ForEach(joinedGroups) { group in
                    NavigationLink(destination: GroupDetailView(group: group)) {
                        GroupRow(group: group)
                    }
                }
            }
            
            Section("Discover Groups") {
                ForEach(nearbyGroups) { group in
                    GroupDiscoveryCard(group: group)
                }
            }
        }
    }
}

struct WhiskyGroup {
    let id: String
    let name: String
    let description: String
    let memberCount: Int
    let location: CLLocation?
    let interests: [String] // "Scotch", "Bourbon", "Japanese"
    let meetupSchedule: String?
    let isPrivate: Bool
}
```

### Tasting Events
**Priority**: High  
**Complexity**: Medium  
**Timeline**: v1.4

Organized tasting events and meetups:

```swift
struct TastingEvent {
    let id: String
    let title: String
    let date: Date
    let location: Location
    let bottles: [Bottle]
    let attendees: [User]
    let maxAttendees: Int
    let price: Decimal?
    let description: String
    let host: User
}

struct EventCheckIn: View {
    let event: TastingEvent
    @State private var currentBottleIndex = 0
    
    var body: some View {
        VStack {
            // Event header
            EventHeader(event: event)
            
            // Current bottle in tasting
            if currentBottleIndex < event.bottles.count {
                let bottle = event.bottles[currentBottleIndex]
                
                VStack {
                    BottleCard(bottle: bottle)
                    
                    // Quick rating for event
                    QuickEventRating(
                        bottle: bottle,
                        event: event,
                        onNext: {
                            currentBottleIndex += 1
                        }
                    )
                }
            }
            
            // Event activity feed
            EventActivityFeed(event: event)
        }
    }
}
```

### Expert Reviews
**Priority**: Low  
**Complexity**: Medium  
**Timeline**: v2.1

Verified expert ratings and reviews:

```swift
struct ExpertReview {
    let id: String
    let expert: Expert
    let bottle: Bottle
    let rating: Double
    let detailedNotes: String
    let tastingConditions: String
    let recommendedServing: ServingStyle
    let pairings: [String]
    let verifiedPurchase: Bool
}

struct Expert {
    let id: String
    let name: String
    let credentials: [String]
    let specialties: [WhiskyCategory]
    let isVerified: Bool
    let followerCount: Int
}
```

## Educational Content

### Whisky Knowledge Base
**Priority**: Medium  
**Complexity**: Low  
**Timeline**: v1.3

In-app educational content:

```swift
struct WhiskyGuide: View {
    var body: some View {
        List {
            Section("Getting Started") {
                GuideArticle(title: "Understanding Whisky Types")
                GuideArticle(title: "How to Taste Whisky")
                GuideArticle(title: "Reading Whisky Labels")
            }
            
            Section("Production") {
                GuideArticle(title: "From Grain to Glass")
                GuideArticle(title: "The Role of Casks")
                GuideArticle(title: "Understanding Age Statements")
            }
            
            Section("Regions") {
                ForEach(WhiskyRegion.allCases) { region in
                    RegionGuide(region: region)
                }
            }
        }
    }
}
```

### Distillery Profiles
**Priority**: High  
**Complexity**: Medium  
**Timeline**: v1.2

Rich distillery information:

```swift
struct DistilleryProfile: View {
    let distillery: Distillery
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Hero image
                DistilleryHeroImage(distillery: distillery)
                
                // Quick facts
                DistilleryFactsCard(
                    founded: distillery.foundedYear,
                    region: distillery.region,
                    owner: distillery.owner,
                    capacity: distillery.annualCapacity
                )
                
                // History
                ExpandableSection(title: "History") {
                    Text(distillery.history)
                }
                
                // Production methods
                ProductionMethodsView(
                    stillTypes: distillery.stillTypes,
                    mashbill: distillery.typicalMashbill,
                    waterSource: distillery.waterSource
                )
                
                // Core range
                Section("Core Range") {
                    ForEach(distillery.coreRange) { bottle in
                        BottleRow(bottle: bottle)
                    }
                }
                
                // Visit information
                if distillery.isOpenToPublic {
                    VisitorInfoCard(distillery: distillery)
                }
            }
        }
    }
}
```

### Interactive Flavor Wheel
**Priority**: Low  
**Complexity**: High  
**Timeline**: v2.0

Visual flavor exploration:

```swift
struct InteractiveFlavorWheel: View {
    @State private var selectedCategory: FlavorCategory?
    @State private var highlightedFlavors: Set<FlavorTag> = []
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Outer ring - main categories
                ForEach(FlavorCategory.allCases) { category in
                    FlavorWheelSegment(
                        category: category,
                        isSelected: selectedCategory == category,
                        startAngle: category.startAngle,
                        endAngle: category.endAngle,
                        radius: geometry.size.width / 2
                    )
                    .onTapGesture {
                        selectedCategory = category
                    }
                }
                
                // Inner ring - specific flavors
                if let category = selectedCategory {
                    ForEach(category.flavors) { flavor in
                        FlavorDetailSegment(
                            flavor: flavor,
                            isHighlighted: highlightedFlavors.contains(flavor)
                        )
                    }
                }
            }
        }
    }
}
```

## Gamification Enhancements

### Advanced Achievements
**Priority**: Medium  
**Complexity**: Low  
**Timeline**: v1.2

More achievement categories:

```swift
enum AchievementCategory {
    case exploration      // Try different regions/styles
    case collection      // Build your collection
    case social          // Friend interactions
    case expertise       // Knowledge-based
    case special         // Time-limited events
    case milestone       // Quantity-based
}

struct AdvancedAchievements {
    static let achievements = [
        // Exploration
        Achievement(
            id: "world-tour",
            name: "World Tour",
            description: "Try whiskies from 10 different countries",
            category: .exploration,
            tiers: [5, 10, 20]
        ),
        
        // Collection
        Achievement(
            id: "vintage-collector",
            name: "Vintage Collector",
            description: "Own bottles from 5 different decades",
            category: .collection
        ),
        
        // Social
        Achievement(
            id: "taste-maker",
            name: "Taste Maker",
            description: "Have 50 users toast your tastings",
            category: .social,
            tiers: [10, 50, 100]
        ),
        
        // Expertise
        Achievement(
            id: "blind-taster",
            name: "Blind Taster",
            description: "Correctly identify 10 whiskies in blind tastings",
            category: .expertise
        ),
        
        // Special
        Achievement(
            id: "burns-night",
            name: "Burns Night",
            description: "Check in a Scotch on January 25th",
            category: .special,
            isTimeLimited: true
        )
    ]
}
```

### Challenges & Competitions
**Priority**: Low  
**Complexity**: Medium  
**Timeline**: v2.0

Time-based challenges:

```swift
struct Challenge {
    let id: String
    let title: String
    let description: String
    let startDate: Date
    let endDate: Date
    let requirements: [ChallengeRequirement]
    let rewards: [Reward]
    let leaderboard: Leaderboard
}

struct MonthlyChallenge: View {
    let challenge: Challenge
    @State private var progress: ChallengeProgress
    
    var body: some View {
        VStack {
            // Challenge header
            ChallengeHeader(
                challenge: challenge,
                daysRemaining: challenge.daysRemaining
            )
            
            // Progress tracker
            ChallengeProgressView(
                requirements: challenge.requirements,
                progress: progress
            )
            
            // Leaderboard preview
            LeaderboardPreview(
                leaderboard: challenge.leaderboard,
                currentUser: progress.rank
            )
            
            // Rewards
            RewardsSection(
                rewards: challenge.rewards,
                unlocked: progress.completedRequirements
            )
        }
    }
}
```

### Regional Exploration
**Priority**: Medium  
**Complexity**: Low  
**Timeline**: v1.3

Encourage exploring different whisky regions:

```swift
struct RegionExplorer: View {
    @State private var exploredRegions: Set<WhiskyRegion> = []
    @State private var regionProgress: [WhiskyRegion: RegionProgress] = [:]
    
    var body: some View {
        ScrollView {
            // World map with explored regions
            WhiskyWorldMap(
                exploredRegions: exploredRegions,
                onRegionTap: { region in
                    selectedRegion = region
                }
            )
            
            // Region progress cards
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))]) {
                ForEach(WhiskyRegion.allCases) { region in
                    RegionProgressCard(
                        region: region,
                        progress: regionProgress[region] ?? .empty,
                        isExplored: exploredRegions.contains(region)
                    )
                }
            }
            
            // Suggested next regions
            if !unexploredRegions.isEmpty {
                SuggestedRegionsSection(
                    regions: unexploredRegions,
                    basedOn: user.tastingPreferences
                )
            }
        }
    }
}
```

## Technical Enhancements

### Apple Watch App
**Priority**: Low  
**Complexity**: High  
**Timeline**: v2.0

Quick logging from Apple Watch:

```swift
struct PeatedWatchApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationView {
                List {
                    // Quick rate last bottle
                    QuickRateView()
                    
                    // Current tasting session
                    if let session = currentSession {
                        ActiveSessionView(session: session)
                    }
                    
                    // Stats glance
                    StatsGlanceView()
                    
                    // Achievements
                    RecentAchievementsView()
                }
            }
        }
    }
}
```

### Widget Support
**Priority**: Medium  
**Complexity**: Medium  
**Timeline**: v1.4

Home screen widgets:

```swift
struct PeatedWidgets: WidgetBundle {
    var body: some Widget {
        // Stats widget
        StatsWidget()
        
        // Recent tasting widget
        RecentTastingWidget()
        
        // Collection widget
        CollectionWidget()
        
        // Daily suggestion widget
        DailySuggestionWidget()
    }
}

struct StatsWidget: Widget {
    let kind: String = "StatsWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StatsProvider()) { entry in
            StatsWidgetView(entry: entry)
        }
        .configurationDisplayName("Whisky Stats")
        .description("Your whisky journey at a glance")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
```

### iPad Optimization
**Priority**: High  
**Complexity**: Medium  
**Timeline**: v1.2

Multi-column layouts for iPad:

```swift
struct iPadLibraryView: View {
    @State private var selectedList: WhiskyList?
    @State private var selectedBottle: Bottle?
    
    var body: some View {
        NavigationSplitView {
            // Sidebar - Lists
            LibraryListsSidebar(selectedList: $selectedList)
        } content: {
            // Content - List items
            if let list = selectedList {
                ListContentView(list: list, selectedBottle: $selectedBottle)
            } else {
                Text("Select a list")
            }
        } detail: {
            // Detail - Bottle view
            if let bottle = selectedBottle {
                BottleDetailView(bottle: bottle)
            } else {
                Text("Select a bottle")
            }
        }
    }
}
```

### CloudKit Sync
**Priority**: Low  
**Complexity**: High  
**Timeline**: v2.1

Multi-device synchronization:

```swift
struct CloudKitSyncManager {
    let container = CKContainer(identifier: "iCloud.com.peated.app")
    
    func setupSync() {
        // Configure record types
        configureRecordTypes()
        
        // Set up subscriptions
        setupSubscriptions()
        
        // Initial sync
        performInitialSync()
    }
    
    func syncTasting(_ tasting: Tasting) async throws {
        let record = CKRecord(recordType: "Tasting")
        record["bottleId"] = tasting.bottle.id
        record["rating"] = tasting.rating
        record["notes"] = tasting.notes
        record["createdAt"] = tasting.createdAt
        
        try await container.privateCloudDatabase.save(record)
    }
}
```

## Monetization Options

### Premium Subscription
**Priority**: TBD  
**Complexity**: Medium  
**Timeline**: TBD

Potential premium features:

```swift
struct PeatedPremium {
    static let features = [
        PremiumFeature(
            id: "unlimited-lists",
            name: "Unlimited Custom Lists",
            freeLimit: 5
        ),
        PremiumFeature(
            id: "advanced-stats",
            name: "Advanced Statistics",
            description: "Detailed analytics and insights"
        ),
        PremiumFeature(
            id: "export-data",
            name: "Export Your Data",
            formats: [.csv, .pdf, .json]
        ),
        PremiumFeature(
            id: "early-access",
            name: "Early Access",
            description: "Try new features first"
        ),
        PremiumFeature(
            id: "ad-free",
            name: "Ad-Free Experience"
        ),
        PremiumFeature(
            id: "exclusive-content",
            name: "Exclusive Content",
            description: "Expert reviews and guides"
        )
    ]
}
```

### Affiliate Programs
**Priority**: TBD  
**Complexity**: Low  
**Timeline**: TBD

Bottle purchase partnerships:

- Retail partner links
- Commission structure
- Price tracking
- Availability alerts
- User opt-in required

## Conclusion

This roadmap represents potential directions for Peated's evolution based on competitive analysis and user needs. Features should be prioritized based on:

1. User feedback and requests
2. Technical feasibility
3. Business objectives
4. Resource availability
5. Market differentiation

Regular review and adjustment of this roadmap will ensure Peated continues to meet user needs while maintaining its core identity as the premier social platform for whisky enthusiasts.