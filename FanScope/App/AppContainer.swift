import FanScopeKit
import Foundation
import OSLog
import SwiftData

@MainActor
final class AppContainer {
    let marketRepository: any MarketRepositoryProtocol
    let onChainRepository: any OnChainRepositoryProtocol
    let watchlistRepository: any WatchlistRepositoryProtocol
    let watchlistViewModel: WatchlistViewModel
    let priceTargetNotifier: PriceTargetNotifier

    init(
        marketRepository: (any MarketRepositoryProtocol)? = nil,
        onChainRepository: (any OnChainRepositoryProtocol)? = nil,
        watchlistRepository: (any WatchlistRepositoryProtocol)? = nil
    ) {
        let httpClient = URLSessionHTTPClient()
        let resolvedMarket = marketRepository ?? DefaultMarketRepository(httpClient: httpClient)
        let resolvedOnChain = onChainRepository ?? DefaultOnChainRepository(httpClient: httpClient)
        let resolvedWatchlist = watchlistRepository ?? Self.makeSwiftDataWatchlistRepository()

        self.marketRepository = resolvedMarket
        self.onChainRepository = resolvedOnChain
        self.watchlistRepository = resolvedWatchlist
        self.watchlistViewModel = WatchlistViewModel(
            watchlistRepository: resolvedWatchlist,
            marketRepository: resolvedMarket
        )
        self.priceTargetNotifier = PriceTargetNotifier()
    }

    func makeMarketListViewModel() -> MarketListViewModel {
        MarketListViewModel(marketRepository: marketRepository)
    }

    func makeTokenDetailViewModel(for token: FanToken) -> TokenDetailViewModel {
        TokenDetailViewModel(
            token: token,
            marketRepository: marketRepository,
            onChainRepository: onChainRepository
        )
    }

    private static func makeSwiftDataWatchlistRepository() -> any WatchlistRepositoryProtocol {
        let schema = Schema([WatchlistItemModel.self])
        if let container = try? ModelContainer(for: schema) {
            return SwiftDataWatchlistRepository(modelContainer: container)
        }

        AppLogger.persistence.error("Disk SwiftData container failed; falling back to in-memory store")
        let memoryConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        if let memoryContainer = try? ModelContainer(for: schema, configurations: [memoryConfig]) {
            return SwiftDataWatchlistRepository(modelContainer: memoryContainer)
        }

        return InMemoryWatchlistRepository()
    }
}
