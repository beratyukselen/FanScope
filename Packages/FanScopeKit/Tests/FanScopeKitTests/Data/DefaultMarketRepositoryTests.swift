import Foundation
import Synchronization
import Testing
@testable import FanScopeKit

@Suite("DefaultMarketRepository")
struct DefaultMarketRepositoryTests {
    private static let paribuTickerJSON = Data(#"""
    [
      {
        "market": "fb_tl",
        "last": "9.56",
        "change": "-0.75",
        "percentage": "-7.27",
        "high": "10.64",
        "low": "9.4",
        "volume": "3070834.04",
        "pair_volume": "30621773.2"
      },
      {
        "market": "gal_tl",
        "last": "39.34",
        "change": "-0.23",
        "percentage": "-0.58",
        "high": "40.10",
        "low": "38.90",
        "volume": "589000.0",
        "pair_volume": "23193147.31"
      },
      {
        "market": "btc_tl",
        "last": "3200000",
        "change": "10000",
        "percentage": "0.31",
        "high": "3250000",
        "low": "3150000",
        "volume": "100",
        "pair_volume": "320000000"
      }
    ]
    """#.utf8)

    private static let coinGeckoJSON = Data(#"""
    [
      {
        "id": "galatasaray-fan-token",
        "symbol": "gal",
        "circulating_supply": 9119350.0,
        "total_supply": 9975000.0,
        "max_supply": 9975000.0,
        "sparkline_in_7d": { "price": [38.5, 39.1, 39.34] }
      }
    ]
    """#.utf8)

    private static let orderBookJSON = Data(#"""
    {
      "bids": [["9.51", "10196.05"], ["9.49", "2002.11"]],
      "asks": [["9.61", "5001"], ["9.62", "7064.94"]]
    }
    """#.utf8)

    @Test("Merges Paribu tickers and CoinGecko enrichment while filtering non-fan markets")
    func mergesParibuAndCoinGecko() async throws {
        let stub = StubHTTPClient { endpoint in
            switch endpoint.host {
            case "api.paribu.com":
                return Self.paribuTickerJSON
            case "api.coingecko.com":
                return Self.coinGeckoJSON
            default:
                throw NetworkError.invalidURL
            }
        }

        let repository = DefaultMarketRepository(httpClient: stub)
        let tokens = try await repository.fetchFanTokens()

        #expect(tokens.count == 2)
        #expect(tokens[0].definition.symbol == "FB")
        #expect(tokens[0].ticker.lastPriceTRY == Decimal(string: "9.56"))
        #expect(tokens[0].supply == nil)

        #expect(tokens[1].definition.symbol == "GAL")
        #expect(tokens[1].supply?.circulatingSupply == 9_119_350.0)
        #expect(tokens[1].sparkline7dTRY == [38.5, 39.1, 39.34])

        // Second call within TTL hits memory cache without triggering new HTTP calls.
        _ = try await repository.fetchFanTokens()
        #expect(stub.requestCount { $0.host == "api.paribu.com" } == 1)
    }

    @Test("Degrades gracefully to stale CoinGecko cache when rate-limited (429)")
    func degradesGracefullyOnCoinGeckoRateLimit() async throws {
        let clock = Mutex(Date(timeIntervalSince1970: 1_795_200_000))
        let stub = StubHTTPClient { endpoint in
            switch endpoint.host {
            case "api.paribu.com":
                return Self.paribuTickerJSON
            case "api.coingecko.com":
                return Self.coinGeckoJSON
            default:
                throw NetworkError.invalidURL
            }
        }

        let repository = DefaultMarketRepository(
            httpClient: stub,
            tokensTTL: 15,
            coinGeckoTTL: 60,
            now: { clock.withLock { $0 } }
        )

        let initial = try await repository.fetchFanTokens()
        #expect(initial.first(where: { $0.definition.symbol == "GAL" })?.sparkline7dTRY.count == 3)

        // Advance past both TTLs and simulate CoinGecko HTTP 429.
        clock.withLock { $0 = $0.addingTimeInterval(120) }
        stub.setResponder { endpoint in
            switch endpoint.host {
            case "api.paribu.com":
                return Self.paribuTickerJSON
            case "api.coingecko.com":
                throw NetworkError.rateLimited(retryAfterSeconds: 60)
            default:
                throw NetworkError.invalidURL
            }
        }

        let refreshed = try await repository.fetchFanTokens()
        let gal = try #require(refreshed.first(where: { $0.definition.symbol == "GAL" }))
        #expect(gal.ticker.lastPriceTRY == Decimal(string: "39.34"))
        #expect(gal.sparkline7dTRY == [38.5, 39.1, 39.34])
    }

    @Test("Decodes Paribu order book levels accurately")
    func decodesOrderBook() async throws {
        let stub = StubHTTPClient { _ in Self.orderBookJSON }
        let repository = DefaultMarketRepository(httpClient: stub)

        let book = try await repository.fetchOrderBook(for: "FB_TL")

        #expect(book.market == "fb_tl")
        #expect(book.bids.count == 2)
        #expect(book.asks.count == 2)
        #expect(book.bids[0].priceTRY == Decimal(string: "9.51"))
        #expect(book.asks[0].amount == 5001)
    }
}
