import Foundation
import Testing
@testable import FanScopeKit

@Suite("OrderBookAnalyzer & SupplyMetrics")
struct OrderBookAnalyzerTests {
    private let analyzer = OrderBookAnalyzer()

    @Test("Computes spread and bid pressure from unsorted levels")
    func computesSpreadAndPressure() throws {
        let book = OrderBook(
            market: "fb_tl",
            bids: [
                OrderBookLevel(priceTRY: try #require(Decimal(string: "9.80")), amount: 100),
                OrderBookLevel(priceTRY: try #require(Decimal(string: "10.00")), amount: 300),
            ],
            asks: [
                OrderBookLevel(priceTRY: try #require(Decimal(string: "10.50")), amount: 200),
                OrderBookLevel(priceTRY: try #require(Decimal(string: "10.20")), amount: 100),
            ]
        )

        let summary = analyzer.summarize(book, depthLimit: 10)

        #expect(summary.bestBid == Decimal(10))
        #expect(summary.bestAsk == Decimal(string: "10.20"))
        #expect(summary.spreadTRY == Decimal(string: "0.20"))

        let spreadPct = try #require(summary.spreadPercentage)
        #expect(abs(spreadPct - 1.960784) < 0.001)

        // Bid volume: 3000 + 980 = 3980; Ask volume: 1020 + 2100 = 3120
        #expect(summary.bidVolumeTRY == Decimal(3980))
        #expect(summary.askVolumeTRY == Decimal(3120))
        #expect(summary.bidPressureRatio > 0.56 && summary.bidPressureRatio < 0.561)
    }

    @Test("Handles empty order book with neutral pressure ratio")
    func handlesEmptyOrderBook() {
        let book = OrderBook(market: "fb_tl", bids: [], asks: [])
        let summary = analyzer.summarize(book)

        #expect(summary.bestBid == nil)
        #expect(summary.bestAsk == nil)
        #expect(summary.spreadTRY == nil)
        #expect(summary.spreadPercentage == nil)
        #expect(summary.bidPressureRatio == 0.5)
    }

    @Test("Computes circulating ratio safely across edge cases")
    func circulatingRatio() throws {
        let normal = SupplyMetrics(circulatingSupply: 9_000_000, totalSupply: 10_000_000, maxSupply: 10_000_000)
        #expect(try #require(normal.circulatingRatio) == 0.9)

        let missing = SupplyMetrics(circulatingSupply: nil, totalSupply: 10_000_000)
        #expect(missing.circulatingRatio == nil)

        let overflow = SupplyMetrics(circulatingSupply: 12_000_000, totalSupply: 10_000_000)
        #expect(try #require(overflow.circulatingRatio) == 1.0)
    }
}
