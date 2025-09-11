# Available Data & Mobile Prioritization

## Overview

Peated.com has extensive whisky data including AI-generated content, pricing information, and detailed metadata. This document outlines what data exists and how to prioritize it for the mobile app to avoid overwhelming users while still providing value.

## Available Data Categories

### 1. Whisky Information

#### Core Data (Phase 1-2)
**Essential for mobile app functionality:**
- Bottle name and basic info
- Brand/Distillery relationships
- ABV
- Category (Scotch, Bourbon, etc.)
- Age statement (if applicable)
- Primary image

#### Extended Data (Phase 3+)
**Nice to have but not critical:**
- AI-generated descriptions
- Tasting notes from the distillery
- Cask type information
- Bottle size variants
- Release year
- Limited edition status

#### Advanced Data (Future)
**Consider for later versions:**
- Production methods
- Mashbill information
- Maturation details
- Bottle history/story
- Awards and accolades

### 2. Geographic Data

#### Core Data (Phase 1-2)
- Country of origin
- Basic region (Highland, Islay, etc.)

#### Extended Data (Phase 3+)
- Detailed region descriptions
- Distillery locations (GPS)
- Regional flavor profiles
- Climate information
- Water source details

### 3. Pricing Information

#### Implementation Strategy
**Phase 2 (Read-only):**
```swift
struct BottlePricing {
    let averagePrice: Decimal?
    let priceRange: PriceRange?
    let currency: String
    let lastUpdated: Date?
    
    // Simple display only
    var displayPrice: String? {
        guard let avg = averagePrice else { return nil }
        return CurrencyFormatter.format(avg, currency: currency)
    }
}
```

**Future (Interactive):**
- Price history graphs
- Where to buy links
- Price alerts
- User-submitted prices

### 4. Achievements System

#### Core Achievements (Phase 3)
Focus on simple, attainable achievements:

```swift
enum CoreAchievements {
    // Milestone based
    case firstTasting           // "Welcome to Peated!"
    case tenTastings           // "Getting Started"
    case fiftyTastings         // "Enthusiast"
    case hundredTastings       // "Century Club"
    
    // Category exploration
    case triedScotch           // "Highlands Calling"
    case triedBourbon          // "American Spirit"
    case triedIrish            // "Irish Eyes"
    case triedJapanese         // "Rising Sun"
    
    // Social
    case firstToast            // "Cheers!"
    case firstComment          // "Conversationalist"
    case tenFollowers          // "Popular"
}
```

#### Advanced Achievements (Future)
Keep these server-side for now:
- Region-specific achievements
- Rare bottle achievements  
- Seasonal/time-based achievements
- Complex multi-condition achievements
- Leaderboard-based achievements

### 5. AI-Generated Content

#### Usage Guidelines

**DO expose in mobile:**
- Brief bottle descriptions (under 100 words)
- Suggested flavor tags
- Simple tasting note templates
- Basic food pairing suggestions

**DON'T expose initially:**
- Long-form distillery histories
- Detailed production essays
- Complex flavor analysis
- Educational content (save for v2)

## Data Display Strategy

### Phase 1-2: Essential Information

```swift
struct MobileBottleData {
    // Core - Always show
    let id: String
    let name: String
    let brand: Brand
    let category: WhiskyCategory
    let abv: Double
    let imageUrl: String?
    
    // Ratings - Always show
    let averageRating: Double
    let totalRatings: Int
    let userRating: Double?
    
    // Optional - Show if available
    let age: Int?
    let region: String?
    let price: BottlePricing?
    
    // Computed
    var displayName: String {
        // Smart formatting based on available data
        if let age = age {
            return "\(name) \(age) Year"
        }
        return name
    }
}
```

### Phase 3+: Enhanced Information

```swift
extension MobileBottleData {
    // Additional data loaded on demand
    struct ExtendedInfo {
        let description: String?        // AI-generated, max 100 words
        let flavorProfile: [FlavorTag]  // AI-suggested
        let similarBottles: [Bottle]    // AI-recommended
        let tastingNotes: String?       // Official notes
        let pairings: [String]          // Simple food pairings
    }
    
    // Load only when viewing bottle detail
    func loadExtendedInfo() async -> ExtendedInfo? {
        // Lazy load from API
    }
}
```

## Implementation Priorities

### Must Have (MVP)
1. Basic bottle information for browsing
2. Search functionality
3. User ratings
4. Core images

### Should Have (v1.0)
1. Pricing data (display only)
2. Basic achievements
3. Region information
4. AI-generated descriptions (brief)

### Nice to Have (v1.x)
1. Detailed flavor profiles
2. AI recommendations
3. Food pairings
4. Extended achievements

### Future Considerations
1. Production details
2. Distillery stories
3. Historical data
4. Market analytics

## Data Loading Strategy

### Optimize for Mobile

```swift
enum DataLoadingStrategy {
    case immediate    // Core data in list views
    case onDemand    // Extended data in detail views
    case background  // Nice-to-have data
    case never       // Not needed on mobile
}

struct DataPriority {
    static let priorities: [String: DataLoadingStrategy] = [
        "name": .immediate,
        "brand": .immediate,
        "rating": .immediate,
        "image": .immediate,
        "price": .onDemand,
        "description": .onDemand,
        "flavorTags": .onDemand,
        "similarBottles": .background,
        "productionDetails": .never,
        "historicalData": .never
    ]
}
```

## API Optimization

### Mobile-Specific Endpoints

Consider creating mobile-optimized endpoints:

```swift
// Instead of returning everything
GET /api/bottles/{id}  // Full 5KB response

// Create mobile-specific versions
GET /api/mobile/bottles/{id}/summary  // 500B essential data
GET /api/mobile/bottles/{id}/extended // 2KB on-demand data
```

### Response Example

```json
// Mobile summary endpoint
{
  "id": "123",
  "name": "Lagavulin 16",
  "brand": { "id": "456", "name": "Lagavulin" },
  "category": "scotch",
  "abv": 43.0,
  "age": 16,
  "imageUrl": "https://...",
  "rating": {
    "average": 4.5,
    "count": 1234,
    "user": 4.0
  },
  "price": {
    "average": 89.99,
    "currency": "USD"
  }
}
```

## Achievement Display Strategy

### Mobile Achievement Tiers

```swift
enum AchievementTier {
    case bronze    // Easy, encouraging engagement
    case silver    // Medium difficulty
    case gold      // Hard, long-term goals
    case platinum  // Very rare, special
}

struct MobileAchievement {
    let id: String
    let name: String
    let description: String
    let emoji: String
    let tier: AchievementTier
    let progress: AchievementProgress?
    
    // Don't sync all achievement data
    static func syncCoreAchievements() async {
        // Only sync ~20-30 core achievements
        // Leave rare/complex ones server-side
    }
}
```

## Recommendations

1. **Start Simple**: Launch with just essential bottle data
2. **Measure Usage**: Track which extended data users actually view
3. **Progressive Enhancement**: Add data based on user behavior
4. **Optimize Payload**: Keep API responses under 1KB for lists
5. **Cache Aggressively**: Extended data rarely changes
6. **Lazy Load**: Don't fetch data until needed
7. **User Control**: Let users choose data usage preferences

## Future Data Opportunities

As the app matures, consider exposing:

1. **Personalized AI Content**
   - Custom tasting note suggestions
   - Personalized bottle recommendations
   - Flavor journey mapping

2. **Community Data**
   - Crowd-sourced tasting notes
   - Regional preferences
   - Seasonal trends

3. **Educational Content**
   - Guided tastings
   - Whisky education
   - Production deep-dives

4. **Market Intelligence**
   - Price trends
   - Availability alerts
   - Investment potential

The key is to start with core functionality and add richness based on user feedback and engagement metrics.