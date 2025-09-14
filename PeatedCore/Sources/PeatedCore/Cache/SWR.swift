import Foundation

/// Minimal SWR helper for "snapshot → cache → render → refresh" flows.
/// Keeps OpenAPI fetchers and SnapshotStore writes pluggable.
public enum SWR {
  /// Seed from an optional seed + cached snapshot, render immediately, then refresh in background.
  /// - Parameters:
  ///   - seed: Optional seed snapshot for instant UI.
  ///   - readSnapshot: Returns the current cached snapshot, if any.
  ///   - fetchFull: Calls the generated OpenAPI client to fetch the full object.
  ///   - writeSnapshot: Persists a new snapshot derived from the fetched object.
  ///   - merge: Combines seed + cached into the best initial snapshot (prefer non-nil from cached).
  ///   - onChanged: Called when a fresh snapshot is available after background refresh.
  /// - Returns: The initial snapshot (merged seed+cache) for first render.
  public static func snapshot<Snapshot, Full>(
    seed: Snapshot?,
    readSnapshot: @escaping @Sendable () async -> Snapshot?,
    fetchFull: @escaping @Sendable () async throws -> Full,
    writeSnapshot: @escaping @Sendable (Full) async -> Void,
    merge: @escaping @Sendable (_ seed: Snapshot?, _ cached: Snapshot?) -> Snapshot?,
    onChanged: @escaping @Sendable (Snapshot) async -> Void
  ) async -> Snapshot? {
    // 1) Initial: merge seed + cache for first render
    let cached = await readSnapshot()
    let initial = merge(seed, cached)

    // 2) Background refresh → write snapshot → emit updated snapshot
    Task.detached(priority: .background) {
      do {
        let full = try await fetchFull()
        await writeSnapshot(full)
        // Re-read snapshot after write to reflect any store-level merge
        if let updated = await readSnapshot() {
          await onChanged(updated)
        }
      } catch {
        // Silently ignore; caller can choose to surface errors elsewhere
      }
    }

    return initial
  }
}
