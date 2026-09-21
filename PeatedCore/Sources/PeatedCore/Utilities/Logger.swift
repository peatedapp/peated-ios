import Foundation
import os.log

/// Centralized logging utility using Apple's unified logging system
public struct Logger {
    // MARK: - Categories

    /// API-related logging (requests, responses, errors)
    public static let api = os.Logger(subsystem: "com.peated.PeatedCore", category: "API")

    /// Model state changes and business logic
    public static let model = os.Logger(subsystem: "com.peated.PeatedCore", category: "Model")

    /// Authentication and user session management
    public static let auth = os.Logger(subsystem: "com.peated.PeatedCore", category: "Auth")

    /// Network connectivity and offline operations
    public static let network = os.Logger(subsystem: "com.peated.PeatedCore", category: "Network")

    /// Database operations and caching
    public static let database = os.Logger(subsystem: "com.peated.PeatedCore", category: "Database")

    /// Sync operations and background tasks
    public static let sync = os.Logger(subsystem: "com.peated.PeatedCore", category: "Sync")

    /// Failures captured for the error reporter
    public static let telemetry = os.Logger(subsystem: "com.peated.PeatedCore", category: "Telemetry")

    // MARK: - Convenience Methods

    /// Log API request with standardized format
    public static func logAPIRequest(
        endpoint: String,
        method: String = "GET"
    ) {
        api.info("API request operation=\(endpoint, privacy: .public) method=\(method, privacy: .public)")
    }

    /// Log API response with standardized format
    public static func logAPIResponse(
        endpoint: String,
        statusCode: Int? = nil,
        resultCount: Int? = nil,
        duration: TimeInterval? = nil
    ) {
        api.info(
            """
            API response
            operation=\(endpoint, privacy: .public)
            status=\(statusCode ?? 0)
            count=\(resultCount ?? 0)
            duration=\(duration ?? 0)
            """
        )
    }

    /// Log API error with context
    public static func logAPIError(
        endpoint: String,
        error: Error,
        method: String,
        duration: TimeInterval
    ) {
        let errorKind = String(describing: type(of: error))
        api.error(
            """
            API failure
            operation=\(endpoint, privacy: .public)
            method=\(method, privacy: .public)
            error=\(errorKind, privacy: .public)
            duration=\(duration)
            """
        )
        Telemetry.log(.error, "API failure", attributes: [
            "operation": .string(endpoint),
            "method": .string(method),
            "error_kind": .string(errorKind),
            "duration_ms": .int(Int(duration * 1000))
        ])
    }

    /// Log model state change
    public static func logModelUpdate(
        modelName: String,
        action: String,
        details: String? = nil
    ) {
        model.info(
            """
            Model update
            model=\(modelName, privacy: .public)
            action=\(action, privacy: .public)
            details=\(details ?? "", privacy: .private)
            """
        )
    }

    /// Log authentication events
    public static func logAuthEvent(
        event: String,
        userId: String? = nil,
        success: Bool = true
    ) {
        auth.info(
            """
            Auth
            event=\(event, privacy: .public)
            success=\(success)
            user=\(userId ?? "", privacy: .private(mask: .hash))
            """
        )
        Telemetry.log(success ? .info : .warning, "Auth event", attributes: [
            "event": .string(event),
            "success": .bool(success)
        ])
    }

    /// Log network connectivity changes
    public static func logNetworkChange(
        connected: Bool,
        connectionType: String? = nil
    ) {
        network.info(
            "Network connected=\(connected) type=\(connectionType ?? "unknown", privacy: .public)"
        )
        Telemetry.addBreadcrumb(TelemetryBreadcrumb(
            category: "network",
            message: connected ? "Network connected" : "Network disconnected",
            level: connected ? .info : .warning,
            data: ["type": .string(connectionType ?? "unknown")]
        ))
    }

    /// Log database operations
    public static func logDatabaseOperation(
        operation: String,
        table: String? = nil,
        recordCount: Int? = nil,
        duration: TimeInterval? = nil
    ) {
        database.info(
            """
            Database
            operation=\(operation, privacy: .public)
            table=\(table ?? "unknown", privacy: .public)
            count=\(recordCount ?? 0)
            duration=\(duration ?? 0)
            """
        )
    }

    /// Log sync operations
    public static func logSyncOperation(
        operation: String,
        entityType: String? = nil,
        count: Int? = nil,
        success: Bool = true
    ) {
        Telemetry.log(success ? .info : .warning, "Sync operation", attributes: [
            "operation": .string(operation),
            "entity": .string(entityType ?? "unknown"),
            "count": .int(count ?? 0),
            "success": .bool(success)
        ])
        if success {
            sync.info(
                """
                Sync
                operation=\(operation, privacy: .public)
                entity=\(entityType ?? "unknown", privacy: .public)
                count=\(count ?? 0)
                success=true
                """
            )
        } else {
            sync.error(
                """
                Sync
                operation=\(operation, privacy: .public)
                entity=\(entityType ?? "unknown", privacy: .public)
                count=\(count ?? 0)
                success=false
                """
            )
        }
    }
}

// MARK: - Privacy Helpers

public extension Logger {
    /// Helper to format user-sensitive data with appropriate privacy levels
    static func formatUserData(_ data: String) -> String {
        data.isEmpty ? "" : "<redacted>"
    }

    /// Helper to format system data (safe to log)
    static func formatSystemData(_ data: Any) -> String {
        String(describing: data)
    }
}
