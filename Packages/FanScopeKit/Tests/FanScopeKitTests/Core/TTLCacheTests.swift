import Foundation
import Synchronization
import Testing
@testable import FanScopeKit

@Suite("TTLCache")
struct TTLCacheTests {
    private final class MutableClock: Sendable {
        private let current: Mutex<Date>

        init(start: Date) {
            self.current = Mutex(start)
        }

        func now() -> Date {
            current.withLock { $0 }
        }

        func advance(by seconds: TimeInterval) {
            current.withLock { date in
                date = date.addingTimeInterval(seconds)
            }
        }
    }

    @Test("Returns fresh values before TTL and serves stale fallback after expiration")
    func expiresAndServesStaleFallback() async {
        let clock = MutableClock(start: Date(timeIntervalSince1970: 1_700_000_000))
        let cache = TTLCache<String, String>(now: { clock.now() })

        await cache.insert("cached-response", for: "markets", ttl: 60)

        #expect(await cache.value(for: "markets") == "cached-response")

        clock.advance(by: 61)

        #expect(await cache.value(for: "markets") == nil)
        #expect(await cache.staleValue(for: "markets") == "cached-response")
    }

    @Test("Removes values completely on explicit invalidation")
    func explicitRemovalClearsFreshAndStale() async {
        let cache = TTLCache<String, Int>()
        await cache.insert(42, for: "fb", ttl: 300)

        await cache.removeValue(for: "fb")

        #expect(await cache.value(for: "fb") == nil)
        #expect(await cache.staleValue(for: "fb") == nil)
        #expect(await cache.count == 0)
    }

    @Test("Supports concurrent writes and reads safely")
    func concurrentAccess() async {
        let cache = TTLCache<Int, Int>()

        await withTaskGroup(of: Void.self) { group in
            for index in 0..<50 {
                group.addTask {
                    await cache.insert(index * 2, for: index, ttl: 120)
                }
            }
        }

        #expect(await cache.count == 50)
        #expect(await cache.value(for: 25) == 50)
    }
}
