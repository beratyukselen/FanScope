import Foundation

public protocol MarketRepositoryProtocol: Sendable {
    func fetchFanTokens(forceRefresh: Bool) async throws -> [FanToken]
    func fetchOrderBook(for market: String) async throws -> OrderBook
}
