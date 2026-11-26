import Foundation
import Synchronization
@testable import FanScopeKit

final class MockMarketRepository: MarketRepositoryProtocol {
    private let tokensResult: Mutex<Result<[FanToken], Error>>
    private let orderBookResult: Mutex<Result<OrderBook, Error>>

    init(
        tokensResult: Result<[FanToken], Error> = .success([]),
        orderBookResult: Result<OrderBook, Error> = .success(OrderBook(market: "fb_tl", bids: [], asks: []))
    ) {
        self.tokensResult = Mutex(tokensResult)
        self.orderBookResult = Mutex(orderBookResult)
    }

    func setTokensResult(_ result: Result<[FanToken], Error>) {
        tokensResult.withLock { $0 = result }
    }

    func fetchFanTokens(forceRefresh: Bool) async throws -> [FanToken] {
        try tokensResult.withLock { $0 }.get()
    }

    func fetchOrderBook(for market: String) async throws -> OrderBook {
        try orderBookResult.withLock { $0 }.get()
    }
}

final class MockOnChainRepository: OnChainRepositoryProtocol {
    private let snapshotResult: Mutex<Result<OnChainSnapshot, Error>>

    init(snapshotResult: Result<OnChainSnapshot, Error>) {
        self.snapshotResult = Mutex(snapshotResult)
    }

    func fetchSnapshot(for token: TokenDefinition, forceRefresh: Bool) async throws -> OnChainSnapshot {
        try snapshotResult.withLock { $0 }.get()
    }
}

final class MockWatchlistRepository: WatchlistRepositoryProtocol {
    private let entries: Mutex<[String: WatchlistEntry]>

    init(initialEntries: [WatchlistEntry] = []) {
        let mapped = Dictionary(
            uniqueKeysWithValues: initialEntries.map { ($0.symbol.uppercased(), $0) }
        )
        self.entries = Mutex(mapped)
    }

    func fetchEntries() async throws -> [WatchlistEntry] {
        entries.withLock { Array($0.values) }
    }

    func upsert(_ entry: WatchlistEntry) async throws {
        entries.withLock { storage in
            storage[entry.symbol.uppercased()] = entry
        }
    }

    func remove(symbol: String) async throws {
        entries.withLock { storage in
            _ = storage.removeValue(forKey: symbol.uppercased())
        }
    }
}
