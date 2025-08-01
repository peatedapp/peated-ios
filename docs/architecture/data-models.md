# Data Models

## Overview

Peated's mobile app uses a simplified data model optimized for performance and offline functionality. We use SQLite for local persistence with a focus on essential data for the mobile experience.

## Core Models (Phase 1-2)

### User

```swift
import Foundation

struct User: Codable, Identifiable {
    // Primary key from API
    let id: String
    
    // Essential info only
    let username: String
    let displayName: String?
    let avatarUrl: String?
    
    // Basic stats (cached)
    let totalTastings: Int
    let totalToasts: Int
    
    // Social status
    let isFollowing: Bool
    let isFollower: Bool
    
    // Computed property for UI
    var displayUsername: String {
        "@\(username)"
    }
}

// Simplified for list views
struct UserSummary: Codable, Identifiable {
    let id: String
    let username: String
    let avatarUrl: String?
}
```

### Bottle (Simplified)

```swift
struct Bottle: Codable, Identifiable {
    // Core identifiers
    let id: String
    let name: String
    let brandId: String
    let brandName: String
    
    // Essential attributes
    let category: WhiskyCategory
    let abv: Double?
    let age: Int?
    
    // Single image URL (not array)
    let imageUrl: String?
    
    // Cached ratings
    let avgRating: Double
    let totalRatings: Int
    let userRating: Double?
    
    // User-specific flags
    let hasHad: Bool
    let isWishlist: Bool
    
    // Computed display name
    var displayName: String {
        if let age = age {
            return "\(name) \(age) Year"
        }
        return name
    }
}

// Even more minimal for search results
struct BottleSummary: Codable, Identifiable {
    let id: String
    let name: String
    let brandName: String
    let imageUrl: String?
    let avgRating: Double
}

enum WhiskyCategory: String, Codable, CaseIterable {
    case scotch = "scotch"
    case bourbon = "bourbon"
    case rye = "rye"
    case irish = "irish"
    case japanese = "japanese"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .scotch: return "Scotch"
        case .bourbon: return "Bourbon"
        case .rye: return "Rye"
        case .irish: return "Irish"
        case .japanese: return "Japanese"
        case .other: return "Other"
        }
    }
}
```

### Tasting

```swift
struct Tasting: Codable, Identifiable {
    let id: String
    
    // Essential data
    let rating: Double
    let notes: String?
    let servingStyle: ServingStyle?
    
    // Single photo URL (not array)
    let photoUrl: String?
    
    // Timestamps
    let createdAt: Date
    
    // Denormalized for performance
    let userId: String
    let username: String
    let userAvatarUrl: String?
    
    let bottleId: String
    let bottleName: String
    let bottleImageUrl: String?
    
    // Social counts
    let toastCount: Int
    let commentCount: Int
    let hasToasted: Bool
    
    // Simplified tags (just strings)
    let tags: [String]
}

enum ServingStyle: String, Codable, CaseIterable {
    case neat = "neat"
    case rocks = "rocks"
    case water = "water"
    
    var displayName: String {
        switch self {
        case .neat: return "Neat"
        case .rocks: return "On the Rocks"
        case .water: return "With Water"
        }
    }
}
```

### Social Models (Minimal)

```swift
struct Toast: Codable {
    let id: String
    let userId: String
    let username: String
    let createdAt: Date
}

struct Comment: Codable, Identifiable {
    let id: String
    let text: String
    let userId: String
    let username: String
    let userAvatarUrl: String?
    let createdAt: Date
}
```

## Extended Models (Phase 3+)

### Bottle Extended Info

```swift
// Loaded on-demand in bottle detail view
struct BottleExtendedInfo: Codable {
    let bottleId: String
    
    // AI-generated content (brief)
    let description: String?      // Max 100 words
    let suggestedTags: [String]   // Flavor suggestions
    
    // Basic pricing (read-only)
    let averagePrice: Decimal?
    let priceRange: PriceRange?
    let priceCurrency: String
    
    // Region info
    let region: String?
    let distilleryName: String?
}

struct PriceRange: Codable {
    let min: Decimal
    let max: Decimal
}
```

### Achievement (Simplified)

```swift
struct Achievement: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let emoji: String
    let tier: AchievementTier
    
    // Progress (optional)
    let currentValue: Int?
    let targetValue: Int?
    let unlockedAt: Date?
    
    var isUnlocked: Bool {
        unlockedAt != nil
    }
    
    var progress: Double? {
        guard let current = currentValue,
              let target = targetValue else { return nil }
        return Double(current) / Double(target)
    }
}

enum AchievementTier: String, Codable {
    case bronze
    case silver
    case gold
}
```

## Offline Support Models

### Pending Action

```swift
// Simple queue for offline actions
struct PendingAction: Codable {
    let id: UUID
    let type: ActionType
    let payload: Data
    let createdAt: Date
    var retryCount: Int = 0
}

enum ActionType: String, Codable {
    case createTasting
    case addToast
    case removeToast
    case addComment
}
```

## SQLite Schema

### Core Tables

```sql
-- Users (cached from API)
CREATE TABLE users (
    id TEXT PRIMARY KEY,
    username TEXT NOT NULL,
    display_name TEXT,
    avatar_url TEXT,
    total_tastings INTEGER DEFAULT 0,
    total_toasts INTEGER DEFAULT 0,
    is_following INTEGER DEFAULT 0,
    is_follower INTEGER DEFAULT 0,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bottles (essential data only)
CREATE TABLE bottles (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    brand_id TEXT,
    brand_name TEXT NOT NULL,
    category TEXT NOT NULL,
    abv REAL,
    age INTEGER,
    image_url TEXT,
    avg_rating REAL DEFAULT 0,
    total_ratings INTEGER DEFAULT 0,
    user_rating REAL,
    has_had INTEGER DEFAULT 0,
    is_wishlist INTEGER DEFAULT 0,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tastings (denormalized for performance)
CREATE TABLE tastings (
    id TEXT PRIMARY KEY,
    rating REAL NOT NULL,
    notes TEXT,
    serving_style TEXT,
    photo_url TEXT,
    created_at TIMESTAMP NOT NULL,
    
    -- Denormalized user data
    user_id TEXT NOT NULL,
    username TEXT NOT NULL,
    user_avatar_url TEXT,
    
    -- Denormalized bottle data
    bottle_id TEXT NOT NULL,
    bottle_name TEXT NOT NULL,
    bottle_image_url TEXT,
    
    -- Social counts
    toast_count INTEGER DEFAULT 0,
    comment_count INTEGER DEFAULT 0,
    has_toasted INTEGER DEFAULT 0,
    
    -- Tags as JSON array
    tags TEXT,
    
    -- Sync status
    sync_status TEXT DEFAULT 'synced'
);

-- Indexes for common queries
CREATE INDEX idx_tastings_user ON tastings(user_id);
CREATE INDEX idx_tastings_bottle ON tastings(bottle_id);
CREATE INDEX idx_tastings_created ON tastings(created_at DESC);
CREATE INDEX idx_bottles_name ON bottles(name);
CREATE INDEX idx_bottles_category ON bottles(category);
```

### Cache Tables

```sql
-- Feed cache
CREATE TABLE feed_cache (
    feed_type TEXT PRIMARY KEY,
    tasting_ids TEXT NOT NULL, -- JSON array
    cursor TEXT,
    has_more INTEGER DEFAULT 1,
    cached_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP
);

-- Search cache
CREATE TABLE search_cache (
    query TEXT PRIMARY KEY,
    result_ids TEXT NOT NULL, -- JSON array
    result_type TEXT NOT NULL, -- 'bottle', 'user', 'mixed'
    cached_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## Data Loading Strategy

### List Views (Immediate)
- User: id, username, avatarUrl
- Bottle: id, name, brandName, imageUrl, avgRating
- Tasting: All fields (already optimized)

### Detail Views (On-Demand)
- BottleExtendedInfo: description, pricing, tags
- User full profile: bio, detailed stats
- Achievement details: progress, unlock criteria

### Never Load on Mobile
- Production details
- Historical data
- Complex analytics
- Long-form AI content

## Query Examples

```swift
// Using SQLite.swift or similar
let bottles = try db.prepare(
    bottlesTable
        .filter(name.like("%\(searchTerm)%"))
        .order(avgRating.desc)
        .limit(20)
)

// Recent tastings with denormalized data
let tastings = try db.prepare(
    tastingsTable
        .order(createdAt.desc)
        .limit(50)
)

// User's library
let myBottles = try db.prepare(
    bottlesTable
        .filter(hasHad == true)
        .order(userRating.desc)
)
```

## Best Practices

1. **Denormalize for Performance**: Store user/bottle info directly in tastings
2. **Single Images**: Use single URL instead of arrays
3. **Lazy Load**: Extended info only when viewing details
4. **Cache Aggressively**: Bottles and users change rarely
5. **Simplify Categories**: Reduce whisky categories for mobile
6. **Limit Achievements**: Start with ~20 core achievements
7. **Defer Complex Data**: Keep AI content brief or skip entirely

This simplified approach ensures fast performance while maintaining all essential functionality for a great mobile experience.