# Missing Pieces for v1 Implementation

## Overview

While our documentation is comprehensive, here are the remaining areas that need definition before starting v1 development.

## 1. API Endpoints & Contracts

### ✅ What's Been Documented
- OpenAPI specification location: https://api.peated.com/spec.json
- Instructions for downloading and generating client code

See: [API Integration](../architecture/api-integration.md)

### What's Still Needed
- Generate the actual Swift client code
- Review endpoints for mobile-specific needs
- Test authentication flow

### Action Required
- [ ] Run OpenAPI generator with the spec
- [ ] Verify all needed endpoints exist
- [ ] Test API authentication

## 2. Design System & Assets

### ✅ What's Been Documented
- Color palette with exact hex values
- Typography scale 
- Spacing system
- Icon set (SF Symbols mapping)
- Component styles (cards, buttons)
- Dark theme guidelines

See: [Design System](../design/design-system.md)

### What's Still Missing
- App icon (all sizes)
- Launch screen design
- Loading state animations
- Empty state illustrations
- Error state designs

### Action Required
- [ ] Create app icon
- [ ] Design launch screen
- [ ] Create loading/empty/error state components

## 3. Launch Configuration

### What's Missing
- App bundle identifier
- App Store metadata
- Launch screen design
- App icon (all sizes)
- Environment URLs (dev, staging, prod)
- API keys and client IDs

### What We Need
```plist
<!-- Info.plist -->
<key>CFBundleIdentifier</key>
<string>com.peated.ios</string>

<key>CFBundleDisplayName</key>
<string>Peated</string>

<key>GOOGLE_CLIENT_ID</key>
<string>?????-?????.apps.googleusercontent.com</string>

<key>API_BASE_URL</key>
<string>https://api.peated.com/v1</string>
```

### Action Required
- [ ] Register app bundle ID
- [ ] Create Google OAuth client
- [ ] Design app icon
- [ ] Create launch screen

## 4. Testing Data

### What's Missing
- Test user accounts
- Sample bottle data
- Test images/photos
- Mock API responses

### What We Need
```swift
// Test data for development
struct TestData {
    static let testUsers = [
        User(id: "test1", username: "whiskyenthusiast"),
        User(id: "test2", username: "bourbonfan")
    ]
    
    static let testBottles = [
        Bottle(id: "1", name: "Lagavulin 16", category: .scotch),
        Bottle(id: "2", name: "Buffalo Trace", category: .bourbon)
    ]
}
```

### Action Required
- [ ] Create test accounts
- [ ] Prepare sample data
- [ ] Set up staging environment

## 5. Analytics & Monitoring

### What's Missing
- Event tracking plan
- Crash reporting setup
- Performance monitoring
- User analytics

### What We Need
```swift
// Analytics events to track
enum AnalyticsEvent {
    case appLaunched
    case userSignedIn(method: String)
    case tastingCreated(bottleId: String, rating: Double)
    case toastAdded(tastingId: String)
    case searchPerformed(query: String, resultCount: Int)
    case bottleViewed(bottleId: String)
}
```

### Action Required
- [ ] Choose analytics provider (if any)
- [ ] Define key metrics
- [ ] Set up crash reporting

## 6. Error Handling & Messaging

### What's Missing
- User-friendly error messages
- Offline mode messaging
- Network error handling
- Validation messages

### What We Need
```swift
enum UserFacingError: LocalizedError {
    case networkUnavailable
    case serverError
    case invalidCredentials
    case tastingCreationFailed
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "No internet connection. Your changes will sync when you're back online."
        case .serverError:
            return "Something went wrong. Please try again."
        case .invalidCredentials:
            return "Invalid email or password."
        case .tastingCreationFailed:
            return "Couldn't create your tasting. Please try again."
        }
    }
}
```

### Action Required
- [ ] Define error messages
- [ ] Create offline messaging
- [ ] Design error UI components

## 7. Privacy & Legal

### What's Missing
- Privacy policy URL
- Terms of service URL
- Data collection disclosure
- Age verification (21+)

### What We Need
- Privacy policy for App Store
- Terms of service
- Age gate implementation
- GDPR compliance (if needed)

### Action Required
- [ ] Create privacy policy
- [ ] Create terms of service
- [ ] Implement age verification

## 8. Release Process

### What's Missing
- Code signing setup
- TestFlight configuration
- Release checklist
- Version numbering strategy

### What We Need
```yaml
# Release checklist
1. Update version and build number
2. Run all tests
3. Archive and upload to App Store Connect
4. Submit for TestFlight review
5. Test on multiple devices
6. Submit for App Store review
```

### Action Required
- [ ] Set up certificates
- [ ] Configure TestFlight
- [ ] Create release process

## Priority for v1

For the MVP, the most critical missing pieces are:

1. **API Specification** - Can't start without this
2. **Design System** - Need colors, fonts, spacing
3. **App Configuration** - Bundle ID, OAuth setup
4. **Basic Assets** - App icon, launch screen

The other items (analytics, comprehensive error handling, etc.) can be refined during development or added post-launch.

## Next Steps

1. Obtain OpenAPI spec from backend team
2. Get design system from design team
3. Set up development environment with test data
4. Create minimal app configuration
5. Begin Phase 1 implementation

With these pieces in place, the v1 implementation can proceed smoothly following the phased approach outlined in the documentation.