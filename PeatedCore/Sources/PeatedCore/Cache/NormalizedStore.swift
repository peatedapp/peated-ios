import Foundation

public struct CacheKey: Hashable, Codable, Sendable {
    public let raw: String
    public init(_ raw: String) {
        self.raw = raw
    }

    public static func user(_ id: String) -> CacheKey {
        .init("user:\(id)")
    }

    public static func bottle(_ id: String) -> CacheKey {
        .init("bottle:\(id)")
    }

    public static func entity(_ id: String) -> CacheKey {
        .init("entity:\(id)")
    }
}

public struct CacheMetadata: Codable, Equatable, Sendable {
    public var etag: String?
    public var lastModified: Date?
    public var expiry: Date?
    public var lastAccessed: Date?
    public init(etag: String? = nil, lastModified: Date? = nil, expiry: Date? = nil, lastAccessed: Date? = nil) {
        self.etag = etag
        self.lastModified = lastModified
        self.expiry = expiry
        self.lastAccessed = lastAccessed
    }
}

public actor NormalizedStore {
    public static let shared = NormalizedStore()

    private var values: [CacheKey: Data] = [:]
    private var metas: [CacheKey: CacheMetadata] = [:]
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private let storeURL: URL
    private var pendingSaveTask: Task<Void, Never>?
    private let saveDebounceNanos: UInt64 = 1_500_000_000 // 1.5s

    // MARK: - Metrics (debug/observability)

    public struct Metrics: Codable, Equatable, Sendable {
        public var gets = 0
        public var hits = 0
        public var misses = 0
        public var upserts = 0
        public var removes = 0
        public var clears = 0
        public var saves = 0
        public var prunedExpired = 0
        public var prunedPrefix = 0
        public var prunedTotal = 0
    }

    private var metrics = Metrics()

    public init() {
        // Determine store URL in Application Support
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? fm.temporaryDirectory
        let dir = base.appendingPathComponent("com.peated.cache", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        storeURL = dir.appendingPathComponent("normalized_store.json")
        // Attempt to load snapshot from disk
        if let data = try? Data(contentsOf: storeURL),
           let snap = try? decoder.decode(Snapshot.self, from: data) {
            values = snap.values
            metas = snap.metas
        }
    }

    public func get<T: Codable>(_ key: CacheKey, as _: T.Type) -> (T, CacheMetadata)? {
        metrics.gets += 1
        guard let data = values[key] else { return nil }
        guard let value = try? decoder.decode(T.self, from: data) else { return nil }
        var meta = metas[key] ?? CacheMetadata()
        meta.lastAccessed = Date()
        metas[key] = meta
        scheduleSave()
        metrics.hits += 1
        return (value, meta)
    }

    public func upsert(_ key: CacheKey, value: some Codable, metadata: CacheMetadata = CacheMetadata()) {
        if let data = try? encoder.encode(value) {
            values[key] = data
            var meta = metadata
            meta.lastAccessed = Date()
            metas[key] = meta
            scheduleSave()
            metrics.upserts += 1
        }
    }

    public func metadata(for key: CacheKey) -> CacheMetadata? {
        metas[key]
    }

    public func remove(_ key: CacheKey) {
        values.removeValue(forKey: key); metas.removeValue(forKey: key); scheduleSave(); metrics.removes += 1
    }

    public func clear() {
        values.removeAll(); metas.removeAll(); scheduleSave(); metrics.clears += 1
    }

    public func flush() {
        saveToDisk()
    }

    private func saveToDisk() {
        let snap = Snapshot(values: values, metas: metas)
        if let data = try? encoder.encode(snap) {
            try? data.write(to: storeURL, options: .atomic)
        }
        metrics.saves += 1
    }

    private func scheduleSave() {
        pendingSaveTask?.cancel()
        pendingSaveTask = Task {
            // Debounce delay
            try? await Task.sleep(nanoseconds: saveDebounceNanos)
            saveToDisk()
        }
    }

    // MARK: - Pruning / Eviction

    /// Remove any entries whose expiry is in the past.
    public func pruneExpired(now: Date = Date()) {
        let keysToRemove = metas.compactMap { key, meta -> CacheKey? in
            if let exp = meta.expiry, exp <= now {
                return key
            }
            return nil
        }
        for k in keysToRemove {
            values.removeValue(forKey: k); metas.removeValue(forKey: k)
        }
        if !keysToRemove.isEmpty {
            scheduleSave(); metrics.prunedExpired += keysToRemove.count
        }
    }

    /// Keep at most `maxEntries` for keys matching the given prefix, evicting least-recently-accessed first.
    public func pruneByPrefix(prefix: String, maxEntries: Int) {
        guard maxEntries > 0 else { return }
        let matching = metas.keys.filter { $0.raw.hasPrefix(prefix) }
        guard matching.count > maxEntries else { return }
        let sorted = matching.sorted { a, b in
            let ma = metas[a]?.lastAccessed ?? Date.distantPast
            let mb = metas[b]?.lastAccessed ?? Date.distantPast
            return ma < mb
        }
        let toRemove = sorted.prefix(sorted.count - maxEntries)
        for k in toRemove {
            values.removeValue(forKey: k); metas.removeValue(forKey: k)
        }
        if !toRemove.isEmpty {
            scheduleSave(); metrics.prunedPrefix += toRemove.count
        }
    }

    /// Enforce a global max entries across the store using LRU eviction.
    public func pruneTotal(maxEntries: Int) {
        guard maxEntries > 0 else { return }
        guard values.count > maxEntries else { return }
        let sorted = metas.keys.sorted { a, b in
            let ma = metas[a]?.lastAccessed ?? Date.distantPast
            let mb = metas[b]?.lastAccessed ?? Date.distantPast
            return ma < mb
        }
        let toRemove = sorted.prefix(values.count - maxEntries)
        for k in toRemove {
            values.removeValue(forKey: k); metas.removeValue(forKey: k)
        }
        if !toRemove.isEmpty {
            scheduleSave(); metrics.prunedTotal += toRemove.count
        }
    }

    /// Snapshot current metrics (consider exporting to Sentry later)
    public func metricsSnapshot() -> Metrics {
        metrics
    }

    // TODO: Migrate cache hit/miss logging to tracing spans (Sentry) for richer insights

    private struct Snapshot: Codable {
        let values: [CacheKey: Data]
        let metas: [CacheKey: CacheMetadata]
    }
}
