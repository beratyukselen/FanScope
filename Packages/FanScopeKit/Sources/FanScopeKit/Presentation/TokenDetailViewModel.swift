import Foundation
import Observation

public struct OrderBookSnapshot: Hashable, Sendable {
    public let orderBook: OrderBook
    public let summary: OrderBookSummary

    public init(orderBook: OrderBook, summary: OrderBookSummary) {
        self.orderBook = orderBook
        self.summary = summary
    }
}

public enum OnChainSectionTab: String, CaseIterable, Identifiable, Sendable {
    case activity
    case holders

    public var id: String { rawValue }
}

public enum OnChainFlowFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case supplyChanges
    case exchangeFlows

    public var id: String { rawValue }

    public func matches(_ kind: OnChainFlowKind) -> Bool {
        switch self {
        case .all:
            return true
        case .supplyChanges:
            return kind == .mint || kind == .burn
        case .exchangeFlows:
            return kind == .exchangeOutflow || kind == .exchangeInflow || kind == .exchangeInternal
        }
    }
}

@MainActor
@Observable
public final class TokenDetailViewModel {
    public let token: FanToken
    public private(set) var orderBookState: LoadState<OrderBookSnapshot> = .idle
    public private(set) var onChainState: LoadState<OnChainSnapshot> = .idle

    public var selectedOnChainTab: OnChainSectionTab = .activity
    public var selectedFlowFilter: OnChainFlowFilter = .all

    private let marketRepository: any MarketRepositoryProtocol
    private let onChainRepository: any OnChainRepositoryProtocol
    private let orderBookAnalyzer: OrderBookAnalyzer

    public init(
        token: FanToken,
        marketRepository: any MarketRepositoryProtocol,
        onChainRepository: any OnChainRepositoryProtocol,
        orderBookAnalyzer: OrderBookAnalyzer = OrderBookAnalyzer()
    ) {
        self.token = token
        self.marketRepository = marketRepository
        self.onChainRepository = onChainRepository
        self.orderBookAnalyzer = orderBookAnalyzer
    }

    /// Combines market-level circulating/max supply (CoinGecko) with live on-chain total supply and holder counts.
    public var mergedSupply: SupplyMetrics {
        let marketSupply = token.supply
        let chainSupply = onChainState.value?.supply

        return SupplyMetrics(
            circulatingSupply: marketSupply?.circulatingSupply ?? chainSupply?.circulatingSupply,
            totalSupply: chainSupply?.totalSupply ?? marketSupply?.totalSupply,
            maxSupply: marketSupply?.maxSupply ?? chainSupply?.maxSupply,
            holdersCount: chainSupply?.holdersCount ?? marketSupply?.holdersCount
        )
    }

    public var filteredOnChainEvents: [OnChainEvent] {
        guard let events = onChainState.value?.events else { return [] }
        return events.filter { selectedFlowFilter.matches($0.kind) }
    }

    public func loadAll(forceRefresh: Bool = false) async {
        async let bookTask: Void = loadOrderBook()
        async let chainTask: Void = loadOnChain(forceRefresh: forceRefresh)
        _ = await (bookTask, chainTask)
    }

    public func loadOrderBook() async {
        if orderBookState.value == nil {
            orderBookState = .loading
        }

        do {
            let book = try await marketRepository.fetchOrderBook(for: token.definition.paribuMarket)
            if book.bids.isEmpty && book.asks.isEmpty {
                orderBookState = .empty
            } else {
                let summary = orderBookAnalyzer.summarize(book, depthLimit: 10)
                orderBookState = .loaded(OrderBookSnapshot(orderBook: book, summary: summary))
            }
        } catch is CancellationError {
            return
        } catch {
            orderBookState = .failed(error.localizedDescription)
        }
    }

    public func loadOnChain(forceRefresh: Bool = false) async {
        if onChainState.value == nil {
            onChainState = .loading
        }

        do {
            let snapshot = try await onChainRepository.fetchSnapshot(
                for: token.definition,
                forceRefresh: forceRefresh
            )
            onChainState = .loaded(snapshot)
        } catch is CancellationError {
            return
        } catch {
            onChainState = .failed(error.localizedDescription)
        }
    }
}
