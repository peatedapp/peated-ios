## General

- PeatedCore is the core library for the Peated iOS app, containing API client, models, services, and database functionality
- Built using modern Swift 6.0 features with strict concurrency enabled
- Uses Swift OpenAPI Generator for type-safe API client generation from OpenAPI spec
- Follows Model-View (MV) pattern with @Observable models for state management
- All public APIs should be properly documented with DocC comments
- Implements offline-first architecture with sync queue for network operations

For comprehensive documentation see:
- @../docs/architecture/overview.md - System architecture
- @../docs/architecture/data-models.md - Data model design
- @../docs/architecture/api-integration.md - API patterns
- @../docs/offline/sync.md - Offline sync architecture

## Architecture

- **API/**: Contains OpenAPI spec and generated client code
- **Models/**: Core data models and @Observable state objects
- **Services/**: Business logic and service layer (managers, repositories)
- **Database/**: SQLite.swift database layer for local storage and offline sync
- **Repositories/**: Data access layer following Repository pattern
- Uses Model-View (MV) pattern - models are @Observable and contain business logic
- Implements offline-first with sync queue for pending operations

## Code Style

- Use 2 spaces for indentation
- Follow Swift API Design Guidelines
- Run `swift format` for code formatting
- Minimize comments in function bodies unless necessary
- See @../Peated/CLAUDE.md for complete code style guidelines

## OpenAPI Integration

- The API client is generated **manually** from `openapi.json` (not at build time)
- Use `../Scripts/update-api-client.sh` to update API bindings
- Configuration is in `openapi-generator-config.yaml`
- Generated code uses `public` access modifier for external visibility
- **Generated files ARE committed** to version control (production approach)
- For complete workflow details see @../docs/openapi-workflow.md

## Testing

- Use Swift Testing framework (not XCTest)
- Aim for high test coverage on services and repositories
- Use in-memory SQLite databases for testing: `Connection(":memory:")`
- Test offline scenarios and sync behavior
- Follow protocol-oriented design for repository mocking

## Offline Sync Architecture

- Store pending operations in SQLite with retry counts and timestamps
- Process sync queue when network becomes available
- Use server timestamps for conflict resolution
- Implement exponential backoff for failed operations
- Track sync status for each entity (syncedAt timestamps)
- Handle conflicts with server-wins strategy

## Security

- OAuth tokens stored via KeychainAccess library
- All API calls use HTTPS with proper certificate validation
- Sensitive data encrypted in local database
- No hardcoded API keys or secrets