import Foundation
import OSLog

public final class DefaultMarketRepository: MarketRepositoryProtocol {
    private struct CoinGeckoEnrichment: Sendable {
        let supply: SupplyMetrics
        let sparkline: [Double]
    }

    private let httpClient: any HTTPClientProtocol
    private let catalog: [TokenDefinition]
    private let tokensCache: TTLCache<String, [FanToken]>
    private let coinGeckoCache: TTLCache<String, [String: CoinGeckoEnrichment]>
    private let orderBookCache: TTLCache<String, OrderBook>

    private let tokensCacheKey = "fan_tokens_all"
    private let coinGeckoCacheKey = "coingecko_markets"
    private let tokensTTL: TimeInterval
    private let coinGeckoTTL: TimeInterval
    private let orderBookTTL: TimeInterval

    public init(
        httpClient: any HTTPClientProtocol,
        catalog: [TokenDefinition] = TokenCatalog.all,
        tokensTTL: TimeInterval = 15,
        coinGeckoTTL: TimeInterval = 300,
        orderBookTTL: TimeInterval = 5,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.httpClient = httpClient
        self.catalog = catalog
        self.tokensTTL = tokensTTL
        self.coinGeckoTTL = coinGeckoTTL
        self.orderBookTTL = orderBookTTL
        self.tokensCache = TTLCache(now: now)
        self.coinGeckoCache = TTLCache(now: now)
        self.orderBookCache = TTLCache(now: now)
    }

    public func fetchFanTokens(forceRefresh: Bool = false) async throws -> [FanToken] {
        if !forceRefresh, let cached = await tokensCache.value(for: tokensCacheKey) {
            return cached
        }

        async let paribuTask: [ParibuTickerDTO] = httpClient.send(FanScopeEndpoints.Paribu.marketTicker())
        async let enrichmentTask = fetchCoinGeckoEnrichment(forceRefresh: forceRefresh)

        let paribuDTOs = try await paribuTask
        let enrichments = try await enrichmentTask

        let tickersByMarket = Dictionary(
            paribuDTOs.compactMap { dto -> (String, MarketTicker)? in
                guard let ticker = dto.toDomain() else { return nil }
                return (dto.market.lowercased(), ticker)
            },
            uniquingKeysWith: { first, _ in first }
        )

        // CoinGecko's sparkline_in_7d is always denominated in USD regardless of vs_currency.
        let usdToTRY = tickersByMarket["usdt_tl"].map {
            NSDecimalNumber(decimal: $0.lastPriceTRY).doubleValue
        }

        let fanTokens = catalog.compactMap { definition -> FanToken? in
            guard let ticker = tickersByMarket[definition.paribuMarket.lowercased()] else {
                return nil
            }
            let enrichment = definition.coinGeckoID.flatMap { enrichments[$0] }
            let rawSparkline = enrichment?.sparkline ?? []
            let convertedSparkline: [Double] = if let rate = usdToTRY, rate > 0 {
                rawSparkline.map { $0 * rate }
            } else {
                rawSparkline
            }
            return FanToken(
                definition: definition,
                ticker: ticker,
                supply: enrichment?.supply,
                sparkline7dTRY: convertedSparkline
            )
        }

        await tokensCache.insert(fanTokens, for: tokensCacheKey, ttl: tokensTTL)
        return fanTokens
    }

    public func fetchOrderBook(for market: String) async throws -> OrderBook {
        let normalizedMarket = market.lowercased()
        if let cached = await orderBookCache.value(for: normalizedMarket) {
            return cached
        }

        let dto: ParibuOrderBookDTO = try await httpClient.send(
            FanScopeEndpoints.Paribu.orderBook(market: normalizedMarket)
        )
        let book = dto.toDomain(market: normalizedMarket)
        await orderBookCache.insert(book, for: normalizedMarket, ttl: orderBookTTL)
        return book
    }

    private func fetchCoinGeckoEnrichment(
        forceRefresh: Bool
    ) async throws -> [String: CoinGeckoEnrichment] {
        if !forceRefresh, let fresh = await coinGeckoCache.value(for: coinGeckoCacheKey) {
            return fresh
        }

        let ids = catalog.compactMap(\.coinGeckoID)
        guard !ids.isEmpty else { return [:] }

        do {
            let dtos: [CoinGeckoMarketDTO] = try await httpClient.send(
                FanScopeEndpoints.CoinGecko.markets(ids: ids)
            )
            let mapped = Dictionary(
                dtos.map { dto in
                    (dto.id, CoinGeckoEnrichment(supply: dto.supplyMetrics, sparkline: dto.sparklinePoints))
                },
                uniquingKeysWith: { first, _ in first }
            )
            await coinGeckoCache.insert(mapped, for: coinGeckoCacheKey, ttl: coinGeckoTTL)
            return mapped
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            AppLogger.network.warning(
                "CoinGecko enrichment unavailable, falling back to stale cache: \(error.localizedDescription, privacy: .public)"
            )
            return await coinGeckoCache.staleValue(for: coinGeckoCacheKey) ?? [:]
        }
    }
}
