import Foundation
import Testing
@testable import FanScopeKit

@Suite("MarketListViewModel")
@MainActor
struct MarketListViewModelTests {
    private static func makeSampleTokens() throws -> [FanToken] {
        let fb = try #require(TokenCatalog.token(forSymbol: "FB"))
        let gal = try #require(TokenCatalog.token(forSymbol: "GAL"))
        let bar = try #require(TokenCatalog.token(forSymbol: "BAR"))

        return [
            FanToken(
                definition: fb,
                ticker: MarketTicker(
                    lastPriceTRY: Decimal(10),
                    change24hTRY: Decimal(1),
                    changePercent24h: 11.1,
                    high24hTRY: Decimal(11),
                    low24hTRY: Decimal(9),
                    volumeToken24h: 500_000,
                    volumeTRY24h: Decimal(5_000_000)
                )
            ),
            FanToken(
                definition: gal,
                ticker: MarketTicker(
                    lastPriceTRY: Decimal(40),
                    change24hTRY: Decimal(-2),
                    changePercent24h: -4.76,
                    high24hTRY: Decimal(42),
                    low24hTRY: Decimal(39),
                    volumeToken24h: 750_000,
                    volumeTRY24h: Decimal(30_000_000)
                )
            ),
            FanToken(
                definition: bar,
                ticker: MarketTicker(
                    lastPriceTRY: Decimal(12),
                    change24hTRY: Decimal(0),
                    changePercent24h: 1.5,
                    high24hTRY: Decimal(13),
                    low24hTRY: Decimal(11),
                    volumeToken24h: 100_000,
                    volumeTRY24h: Decimal(1_200_000)
                )
            ),
        ]
    }

    @Test("Loads tokens, computes market summary, and supports category filtering and sorting")
    func loadsFiltersAndSorts() async throws {
        let tokens = try Self.makeSampleTokens()
        let repo = MockMarketRepository(tokensResult: .success(tokens))
        let viewModel = MarketListViewModel(marketRepository: repo, debounceNanoseconds: 0)

        await viewModel.load()

        #expect(viewModel.state == .loaded(tokens))
        #expect(viewModel.totalVolumeTRY24h == Decimal(36_200_000))
        #expect(viewModel.topGainer?.definition.symbol == "FB")

        viewModel.selectedCategory = .turkishClubs
        #expect(viewModel.filteredTokens.map(\.definition.symbol) == ["FB", "GAL"])

        viewModel.sortOption = .volumeDescending
        #expect(viewModel.filteredTokens.map(\.definition.symbol) == ["GAL", "FB"])

        viewModel.selectedCategory = .all
        viewModel.searchText = "barce"
        #expect(viewModel.filteredTokens.map(\.definition.symbol) == ["BAR"])
    }

    @Test("Transitions to failed state on initial error and preserves data during silent refresh failure")
    func errorHandlingAndSilentRefresh() async throws {
        let tokens = try Self.makeSampleTokens()
        let repo = MockMarketRepository(tokensResult: .failure(NetworkError.httpStatus(code: 500)))
        let viewModel = MarketListViewModel(marketRepository: repo, debounceNanoseconds: 0)

        await viewModel.load()
        #expect(viewModel.state.errorMessage != nil)

        repo.setTokensResult(.success(tokens))
        await viewModel.load(forceRefresh: true)
        #expect(viewModel.state == .loaded(tokens))

        // Transient polling failure must keep loaded market data visible.
        repo.setTokensResult(.failure(NetworkError.transportFailed("offline")))
        await viewModel.refreshSilently()
        #expect(viewModel.state == .loaded(tokens))
    }

    @Test("Transitions to empty state when repository returns no fan tokens")
    func handlesEmptyList() async {
        let repo = MockMarketRepository(tokensResult: .success([]))
        let viewModel = MarketListViewModel(marketRepository: repo, debounceNanoseconds: 0)

        await viewModel.load()
        #expect(viewModel.state == .empty)
    }
}
