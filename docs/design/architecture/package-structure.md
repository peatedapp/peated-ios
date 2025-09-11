# Package Structure

## Overview

The Peated iOS project is organized into three distinct Swift packages to improve build times, maintainability, and separation of concerns.

```
peated-ios/
├── Peated/           # Main iOS app target
├── PeatedAPI/        # Generated API client (separate package)
└── PeatedCore/       # Business logic and core functionality
```

## Why Three Packages?

### 1. Build Performance
- **PeatedAPI** contains 70,000+ lines of generated code
- Keeping it separate prevents constant recompilation
- Changes to business logic don't trigger API regeneration
- Parallel compilation of packages

### 2. Clear Boundaries
- **Peated**: UI and user-facing features only
- **PeatedAPI**: Pure generated code, no manual edits
- **PeatedCore**: All business logic, models, and services

### 3. Maintenance
- API updates are isolated to PeatedAPI
- Can update API client without touching app code
- Easy to see what changed in pull requests

## Package Details

### Peated (Main App)

**Purpose**: iOS application target with UI and user experience

**Contains**:
- SwiftUI Views
- View-specific models (@Observable)
- Navigation logic
- App lifecycle management
- Asset catalogs and resources

**Dependencies**:
- PeatedCore (for all business logic)
- No direct dependency on PeatedAPI

**Key Directories**:
```
Peated/
├── App/              # App entry point, root view
├── Features/         # Feature modules (Feed, Profile, etc.)
├── Common/           # Shared UI components
└── Resources/        # Assets, Info.plist
```

### PeatedAPI (Generated Client)

**Purpose**: Auto-generated API client from OpenAPI specification

**Contains**:
- Generated `Client.swift` (~5,000 lines)
- Generated `Types.swift` (~70,000 lines)
- OpenAPI specification (`openapi.json`)
- Generation scripts and configuration

**Dependencies**:
- OpenAPIRuntime
- OpenAPIURLSession

**Key Files**:
```
PeatedAPI/
├── Sources/PeatedAPI/
│   ├── Generated/
│   │   ├── Client.swift      # Generated API client
│   │   └── Types.swift       # Generated types
│   ├── openapi.json          # Source specification
│   └── openapi-generator-config.yaml
├── update-api.sh             # Update script
├── fix-nullable-fields.sh    # Preprocessing
└── Package.swift
```

⚠️ **WARNING**: This package should NEVER be edited manually. All changes come from regeneration.

### PeatedCore (Business Logic)

**Purpose**: Core business logic, models, and services

**Contains**:
- Domain models
- Repository implementations
- Authentication services
- Database layer (SQLite)
- Offline sync logic
- Utilities and extensions

**Dependencies**:
- PeatedAPI (for API types)
- SQLite.swift
- KeychainAccess
- Other core dependencies

**Key Directories**:
```
PeatedCore/
├── Sources/PeatedCore/
│   ├── Models/          # Domain models
│   ├── Services/        # Business services
│   ├── Repositories/    # Data access layer
│   ├── Database/        # SQLite persistence
│   ├── Utilities/       # Helpers and extensions
│   └── Middleware/      # API middleware
└── Tests/               # Unit tests
```

## Import Rules

### ✅ Allowed Imports

```swift
// In Peated (app target)
import SwiftUI
import PeatedCore  // ✅ Access all business logic

// In PeatedCore
import Foundation
import PeatedAPI   // ✅ Access generated types
import SQLite

// In PeatedAPI
import OpenAPIRuntime  // ✅ Required for generation
import OpenAPIURLSession
```

### ❌ Forbidden Imports

```swift
// In Peated (app target)
import PeatedAPI  // ❌ Never import directly

// In PeatedAPI
import PeatedCore // ❌ Would create circular dependency
```

## Development Workflow

### Making UI Changes
1. Work in the `Peated` package
2. Use models from `PeatedCore`
3. No need to touch other packages

### Adding Business Logic
1. Work in `PeatedCore` package
2. Create repositories for data access
3. Expose public APIs for the app

### Updating API
1. **STOP** - Read the warnings in openapi-workflow.md
2. Work in `PeatedAPI` package only
3. Run `update-api.sh` script
4. Fix any breaking changes in `PeatedCore`
5. App should continue to work

## Build Tips

### Faster Builds
- Build packages independently when possible
- Use `swift build` in package directories
- Xcode will cache package builds

### Clean Builds
```bash
# Clean everything
rm -rf ~/Library/Developer/Xcode/DerivedData

# Clean specific package
cd PeatedCore
swift package clean
```

### Troubleshooting Imports
If you see "No such module" errors:
1. Check package dependencies in Package.swift
2. Ensure packages are resolved: `swift package resolve`
3. Clean and rebuild

## Benefits of This Structure

1. **Isolation**: API changes don't cascade everywhere
2. **Performance**: Faster incremental builds
3. **Clarity**: Clear ownership and responsibilities
4. **Testing**: Easy to test packages independently
5. **Modularity**: Could extract packages for reuse

## Future Considerations

- PeatedAPI could become a separate repository
- PeatedCore could be used by other clients (macOS, watchOS)
- Additional packages for specific features
- Shared package for cross-platform code