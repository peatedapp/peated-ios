# Peated iOS App Documentation

## Overview

Peated is a native iOS application for whisky enthusiasts to track, rate, and discover whiskies. Inspired by Untappd's social features, Peated creates a community around whisky appreciation.

## Quick Links

### Architecture
- [Architecture Overview](architecture/overview.md) - High-level system design
- [Technology Stack](architecture/tech-stack.md) - Core technologies and frameworks
- [Data Models](architecture/data-models.md) - SQLite schema and models
- [API Integration](architecture/api-integration.md) - OpenAPI SDK and authentication
- [Available Data](data/available-data.md) - Existing data and mobile prioritization

### Design
- [Design System](design/design-system.md) - Colors, typography, and components

### Components
- [Component Library](components/README.md) - Reusable UI components
- [TastingCard](components/tasting-card.md) - Main feed item component
- [Navigation](components/navigation/tab-bar.md) - Custom tab bar implementation

### Screens
- [Screen Inventory](screens/README.md) - Complete list of app screens
- [Authentication](screens/auth/login.md) - Login, registration, and onboarding
- [Activity Feed](screens/activity/feed.md) - Main social feed
- [Search & Discovery](screens/search/search.md) - Finding bottles and users
- [Tasting Creation](screens/creation/flow-overview.md) - 5-step check-in process
- [Library](screens/library/library.md) - Personal whisky collection
- [Profile](screens/profile/profile.md) - User profiles and settings

### Features
- [Social Features](features/social/toasts.md) - Toasts, comments, and following
- [Offline Support](features/offline/sync.md) - Offline-first architecture
- [Notifications](features/notifications/push.md) - Push and in-app notifications

### Implementation
- [Development Phases](implementation/phases.md) - Roadmap and milestones
- [Dependencies](implementation/dependencies.md) - Required packages and tools
- [Testing Strategy](implementation/testing.md) - Unit, integration, and UI testing
- [Future Roadmap](future/roadmap.md) - Post-launch feature ideas

## Key Features

### Core Functionality
- **Whisky Check-ins**: Rate and review whiskies with photos and tasting notes
- **Social Feed**: Follow friends and discover what they're drinking
- **Discovery**: Search extensive whisky database and find new favorites
- **Personal Library**: Track your whisky journey with detailed statistics

### Social Features
- **Toasts**: Like system for appreciating others' tastings
- **Comments**: Engage in discussions about specific tastings
- **Following**: Build your whisky community
- **Sharing**: Share tastings on social media

### Technical Highlights
- **SwiftUI**: Modern declarative UI framework
- **SwiftData**: Apple's latest persistence framework
- **OpenAPI**: Type-safe API client generation
- **Offline-First**: Full functionality even without connection
- **Local State Caching**: Intelligent caching for optimal mobile performance

## Getting Started

1. Review the [Architecture Overview](architecture/overview.md)
2. Understand the [Data Models](architecture/data-models.md)
3. Explore the [Screen Inventory](screens/README.md)
4. Check the [Development Phases](implementation/phases.md)

## Design Principles

1. **User-Centric**: Every feature enhances the whisky discovery experience
2. **Performance**: Smooth 60fps scrolling even with rich media
3. **Offline-First**: Core features work without internet connection
4. **Accessibility**: Full VoiceOver support and Dynamic Type
5. **Privacy**: User controls over data sharing and visibility

## Target Audience

- Whisky enthusiasts tracking their tasting journey
- Social drinkers sharing experiences with friends
- Collectors managing their whisky library
- Beginners discovering new whiskies through community recommendations

## Success Metrics

- Daily active users engaging with the feed
- Average tastings per user per month
- Social interactions (toasts and comments)
- User retention after 30 days
- App Store rating above 4.5 stars