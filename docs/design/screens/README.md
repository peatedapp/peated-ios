# Screens Documentation

## Overview

This section documents all screens in the Peated iOS app. Each screen specification includes layout, navigation, data requirements, and interaction patterns.

## Screen Hierarchy

### Authentication Flow
- [Login Screen](auth/login.md) - Email/password and Google OAuth login
- [Registration Screen](auth/register.md) - New user account creation
- [Onboarding Flow](auth/onboarding.md) - First-time user experience

### Main Navigation (Tab-Based)

#### Activity Tab
- [Activity Feed](activity/feed.md) - Main social feed of tastings
- [Tasting Detail](activity/tasting-detail.md) - Full view of a single tasting

#### Search Tab
- [Search Screen](search/search.md) - Unified search for bottles, users, locations
- [Bottle Detail](search/bottle-detail.md) - Complete bottle information
- [User Profile](search/user-profile.md) - Other users' profiles

#### Library Tab
- [Library Screen](library/library.md) - Personal whisky collection

#### Profile Tab
- [Profile Screen](profile/profile.md) - Current user's profile
- [Settings Screen](profile/settings.md) - App preferences and account settings

### Modal Flows

#### Tasting Creation (5-Step Flow)
- [Flow Overview](creation/flow-overview.md) - Complete creation process
- [Bottle Selection](creation/bottle-select.md) - Step 1: Choose whisky
- [Rating & Notes](creation/rating-notes.md) - Step 2: Rate and describe
- [Location](creation/location.md) - Step 3: Where are you drinking
- [Photos](creation/photos.md) - Step 4: Add images
- [Confirmation](creation/confirm.md) - Step 5: Review and post

## Screen Documentation Standards

Each screen documentation includes:

### 1. Overview
- Purpose and context
- User journey position
- Key functionality

### 2. Visual Layout
- ASCII mockup or wireframe
- Component hierarchy
- Responsive considerations

### 3. Navigation
- How users arrive at this screen
- Available navigation options
- Deep linking support

### 4. Data Requirements
- Required data models
- API endpoints used
- Loading strategies

### 5. State Management
- Screen-level state
- Shared state dependencies
- State transitions

### 6. Interactions
- User actions available
- Gesture support
- Feedback mechanisms

### 7. Edge Cases
- Empty states
- Error states
- Loading states
- Offline behavior

### 8. Accessibility
- VoiceOver annotations
- Focus management
- Keyboard navigation

### 9. Performance
- Optimization strategies
- Lazy loading
- Memory considerations

## Navigation Patterns

### Tab Navigation
- Persistent bottom tab bar
- State preservation per tab
- Badge notifications

### Stack Navigation
- Push/pop within each tab
- Modal presentations
- Full-screen covers

### Deep Linking
```
peated://bottle/{id}     - Open bottle detail
peated://user/{username} - Open user profile  
peated://tasting/{id}    - Open tasting detail
peated://checkin         - Start new tasting
```

## Screen States

### Loading States
Every screen must handle:
- Initial load
- Refresh
- Pagination
- Background updates

### Error States
Consistent error handling:
- Network errors
- API errors
- Validation errors
- Permission errors

### Empty States
Meaningful empty content:
- First-time user guidance
- Action prompts
- Illustrations

## Responsive Design

### Device Support
- iPhone SE (375pt width)
- iPhone 14 (390pt width)
- iPhone 14 Pro Max (430pt width)
- iPad (future consideration)

### Orientation
- Portrait primary
- Landscape for photo viewing
- Lock orientation during flows

## Animation Guidelines

### Transitions
- Navigation: 0.35s ease-in-out
- Modal: 0.4s spring
- List items: 0.2s ease-out

### Micro-interactions
- Button taps: Scale 0.95
- Refresh: Rubber band
- Loading: Pulse or spin

## Testing Considerations

### Screen Testing
- Unit tests for ViewModels
- Snapshot tests for layouts
- UI tests for critical paths
- Accessibility audits

### Test Scenarios
- New user journey
- Returning user flow
- Offline → online transition
- Error recovery