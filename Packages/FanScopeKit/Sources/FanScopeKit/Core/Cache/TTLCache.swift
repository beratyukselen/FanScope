import Foundation

public actor TTLCache<Key: Hashable & Sendable, Value: Sendable> {
    private struct Entry {
        let value: Value
        let expiresAt: Date
    }

    private var storage: [Key: Entry] = [:]
    private let now: @Sendable () -> Date

    public init(now: @escaping @Sendable () -> Date = Date.init) {
        self.now = now
    }

    public func value(for key: Key) -> Value? {
        guard let entry = storage[key] else {
            return nil
        }
        guard entry.expiresAt > now() else {
            return nil
        }
        return entry.value
    }

    /// Returns the cached value even after expiration so callers can degrade gracefully on upstream rate limits.
    public func staleValue(for key: Key) -> Value? {
        storage[key]?.value
    }

    public func insert(_ value: Value, for key: Key, ttl: TimeInterval) {
        let expiration = now().addingTimeInterval(max(0, ttl))
        storage[key] = Entry(value: value, expiresAt: expiration)
    }

    public func removeValue(for key: Key) {
        storage.removeValue(forKey: key)
    }

    public func removeAll() {
        storage.removeAll()
    }

    public var count: Int {
        storage.count
    }
}
