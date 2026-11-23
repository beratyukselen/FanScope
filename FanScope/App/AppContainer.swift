import FanScopeKit
import Foundation

@MainActor
final class AppContainer {
    let marketRepository: any MarketRepositoryProtocol
    let onChainRepository: any OnChainRepositoryProtocol

    init(
        marketRepository: (any MarketRepositoryProtocol)? = nil,
        onChainRepository: (any OnChainRepositoryProtocol)? = nil
    ) {
        let httpClient = URLSessionHTTPClient()
        self.marketRepository = marketRepository ?? DefaultMarketRepository(httpClient: httpClient)
        self.onChainRepository = onChainRepository ?? DefaultOnChainRepository(httpClient: httpClient)
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
}
