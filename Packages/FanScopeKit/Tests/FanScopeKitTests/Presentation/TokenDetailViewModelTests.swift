import Foundation
import Testing
@testable import FanScopeKit

@Suite("TokenDetailViewModel")
@MainActor
struct TokenDetailViewModelTests {
    private static func makeToken(symbol: String, supply: SupplyMetrics?) throws -> FanToken {
        let definition = try #require(TokenCatalog.token(forSymbol: symbol))
        return FanToken(
            definition: definition,
            ticker: MarketTicker(
                lastPriceTRY: Decimal(10),
                change24hTRY: Decimal(0),
                changePercent24h: 0,
                high24hTRY: Decimal(11),
                low24hTRY: Decimal(9),
                volumeToken24h: 1000,
                volumeTRY24h: Decimal(10_000)
            ),
            supply: supply
        )
    }

    @Test("Loads order book and on-chain snapshot independently and merges supply metrics")
    func loadsIndependentlyAndMergesSupply() async throws {
        let token = try Self.makeToken(
            symbol: "GAL",
            supply: SupplyMetrics(circulatingSupply: 9_100_000, totalSupply: 9_975_000, maxSupply: 9_975_000)
        )
        let orderBook = OrderBook(
            market: "gal_tl",
            bids: [OrderBookLevel(priceTRY: Decimal(39), amount: 200)],
            asks: [OrderBookLevel(priceTRY: Decimal(40), amount: 100)]
        )
        let mintEvent = OnChainEvent(
            id: "1",
            txHash: "0x1",
            timestamp: Date(),
            kind: .mint,
            amount: 50_000,
            fromAddress: KnownWalletRegistry.nullAddress,
            fromLabel: "Null Address",
            toAddress: "0xabc",
            toLabel: nil,
            network: .chiliz
        )
        let outflowEvent = OnChainEvent(
            id: "2",
            txHash: "0x2",
            timestamp: Date(),
            kind: .exchangeOutflow,
            amount: 20_000,
            fromAddress: KnownWalletRegistry.primaryExchangeHotWallet,
            fromLabel: "Paribu Hot Wallet",
            toAddress: "0xdef",
            toLabel: nil,
            network: .chiliz
        )
        let snapshot = OnChainSnapshot(
            supply: SupplyMetrics(totalSupply: 9_639_243, holdersCount: 420),
            events: [mintEvent, outflowEvent],
            holders: [],
            monthlySummary: MonthlyFlowSummary(
                mintedAmount: 50_000,
                burnedAmount: 0,
                exchangeOutflowAmount: 20_000,
                exchangeInflowAmount: 0,
                eventCount: 2
            )
        )

        let viewModel = TokenDetailViewModel(
            token: token,
            marketRepository: MockMarketRepository(orderBookResult: .success(orderBook)),
            onChainRepository: MockOnChainRepository(snapshotResult: .success(snapshot))
        )

        await viewModel.loadAll()

        #expect(viewModel.orderBookState.value?.summary.bestBid == Decimal(39))
        #expect(viewModel.onChainState.value?.events.count == 2)

        // Merged supply prefers live on-chain totalSupply + holdersCount while retaining CoinGecko circulating/max.
        #expect(viewModel.mergedSupply.circulatingSupply == 9_100_000)
        #expect(viewModel.mergedSupply.totalSupply == 9_639_243)
        #expect(viewModel.mergedSupply.maxSupply == 9_975_000)
        #expect(viewModel.mergedSupply.holdersCount == 420)

        viewModel.selectedFlowFilter = .supplyChanges
        #expect(viewModel.filteredOnChainEvents.map(\.id) == ["1"])

        viewModel.selectedFlowFilter = .exchangeFlows
        #expect(viewModel.filteredOnChainEvents.map(\.id) == ["2"])
    }

    @Test("Keeps on-chain section loaded when order book request fails")
    func isolatesSectionFailures() async throws {
        let token = try Self.makeToken(symbol: "FB", supply: nil)
        let snapshot = OnChainSnapshot(
            supply: SupplyMetrics(totalSupply: 41_296_676, holdersCount: 196),
            events: [],
            holders: [],
            monthlySummary: MonthlyFlowSummary(
                mintedAmount: 0,
                burnedAmount: 0,
                exchangeOutflowAmount: 0,
                exchangeInflowAmount: 0,
                eventCount: 0
            )
        )

        let viewModel = TokenDetailViewModel(
            token: token,
            marketRepository: MockMarketRepository(orderBookResult: .failure(NetworkError.httpStatus(code: 503))),
            onChainRepository: MockOnChainRepository(snapshotResult: .success(snapshot))
        )

        await viewModel.loadAll()

        #expect(viewModel.orderBookState.errorMessage != nil)
        #expect(viewModel.onChainState.value?.supply.totalSupply == 41_296_676)
    }
}
