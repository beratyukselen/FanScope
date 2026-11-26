import Foundation
import Testing
@testable import FanScopeKit

@Suite("WatchlistViewModel")
@MainActor
struct WatchlistViewModelTests {
    private static func makeToken(symbol: String, priceTRY: Decimal) throws -> FanToken {
        let definition = try #require(TokenCatalog.token(forSymbol: symbol))
        return FanToken(
            definition: definition,
            ticker: MarketTicker(
                lastPriceTRY: priceTRY,
                change24hTRY: Decimal(0),
                changePercent24h: 2.5,
                high24hTRY: priceTRY + 1,
                low24hTRY: max(priceTRY - 1, 1),
                volumeToken24h: 100_000,
                volumeTRY24h: Decimal(1_000_000)
            )
        )
    }

    @Test("Pairs persisted watchlist entries with live prices and computes reached target counts")
    func loadsEntriesAndEvaluatesTargets() async throws {
        let fb = try Self.makeToken(symbol: "FB", priceTRY: Decimal(13))
        let gal = try Self.makeToken(symbol: "GAL", priceTRY: Decimal(38))

        let entries = [
            WatchlistEntry(
                symbol: "FB",
                targetPriceTRY: Decimal(12.5),
                targetDirection: .above,
                note: "Derby week target",
                createdAt: Date(timeIntervalSince1970: 2_000)
            ),
            WatchlistEntry(
                symbol: "GAL",
                targetPriceTRY: Decimal(35),
                targetDirection: .below,
                note: "Dip buy zone",
                createdAt: Date(timeIntervalSince1970: 1_000)
            ),
        ]

        let viewModel = WatchlistViewModel(
            watchlistRepository: MockWatchlistRepository(initialEntries: entries),
            marketRepository: MockMarketRepository(tokensResult: .success([fb, gal]))
        )

        await viewModel.load()

        #expect(viewModel.rows.count == 2)
        #expect(viewModel.isWatched("FB"))
        #expect(viewModel.reachedTargetCount == 1)
        #expect(viewModel.rows[0].entry.symbol == "FB")
        #expect(viewModel.rows[0].targetStatus?.isReached == true)
        #expect(viewModel.rows[1].targetStatus?.isReached == false)
    }

    @Test("Renders persisted entries offline when live market fetch fails")
    func rendersOfflineEntriesOnMarketFailure() async {
        let entries = [
            WatchlistEntry(symbol: "BJK", targetPriceTRY: Decimal(9), note: "Offline note")
        ]
        let viewModel = WatchlistViewModel(
            watchlistRepository: MockWatchlistRepository(initialEntries: entries),
            marketRepository: MockMarketRepository(tokensResult: .failure(NetworkError.httpStatus(code: 503)))
        )

        await viewModel.load()

        #expect(viewModel.rows.count == 1)
        #expect(viewModel.rows[0].entry.symbol == "BJK")
        #expect(viewModel.rows[0].definition?.symbol == "BJK")
        #expect(viewModel.rows[0].token == nil)
        #expect(viewModel.rows[0].targetStatus == nil)
    }

    @Test("Supports toggling, saving targets, and removing entries until empty")
    func mutatesWatchlistLifecycle() async throws {
        let fb = try Self.makeToken(symbol: "FB", priceTRY: Decimal(10))
        let viewModel = WatchlistViewModel(
            watchlistRepository: MockWatchlistRepository(),
            marketRepository: MockMarketRepository(tokensResult: .success([fb]))
        )

        await viewModel.load()
        #expect(viewModel.state == .empty)

        await viewModel.toggleWatch(symbol: "FB")
        #expect(viewModel.isWatched("FB"))
        #expect(viewModel.rows.count == 1)

        await viewModel.saveTarget(
            symbol: "FB",
            targetPriceTRY: Decimal(15),
            direction: .above,
            note: "  Sell half  "
        )
        #expect(viewModel.entry(for: "FB")?.targetPriceTRY == Decimal(15))
        #expect(viewModel.entry(for: "FB")?.note == "Sell half")

        await viewModel.remove(symbol: "FB")
        #expect(!viewModel.isWatched("FB"))
        #expect(viewModel.state == .empty)
    }
}
