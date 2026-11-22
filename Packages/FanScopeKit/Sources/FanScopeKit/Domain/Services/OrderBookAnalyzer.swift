import Foundation

public struct OrderBookAnalyzer: Sendable {
    public init() {}

    public func summarize(_ orderBook: OrderBook, depthLimit: Int = 10) -> OrderBookSummary {
        let topBids = Array(
            orderBook.bids
                .sorted { $0.priceTRY > $1.priceTRY }
                .prefix(depthLimit)
        )
        let topAsks = Array(
            orderBook.asks
                .sorted { $0.priceTRY < $1.priceTRY }
                .prefix(depthLimit)
        )

        let bestBid = topBids.first?.priceTRY
        let bestAsk = topAsks.first?.priceTRY

        var spreadTRY: Decimal?
        var spreadPercentage: Double?

        if let bestBid, let bestAsk, bestAsk > 0, bestAsk >= bestBid {
            let spread = bestAsk - bestBid
            spreadTRY = spread
            let spreadDouble = NSDecimalNumber(decimal: spread).doubleValue
            let askDouble = NSDecimalNumber(decimal: bestAsk).doubleValue
            spreadPercentage = (spreadDouble / askDouble) * 100.0
        }

        let bidVolumeTRY = topBids.reduce(Decimal.zero) { $0 + $1.totalTRY }
        let askVolumeTRY = topAsks.reduce(Decimal.zero) { $0 + $1.totalTRY }

        let bidDouble = NSDecimalNumber(decimal: bidVolumeTRY).doubleValue
        let askDouble = NSDecimalNumber(decimal: askVolumeTRY).doubleValue
        let totalVolume = bidDouble + askDouble
        let bidPressureRatio = totalVolume > 0 ? (bidDouble / totalVolume) : 0.5

        return OrderBookSummary(
            bestBid: bestBid,
            bestAsk: bestAsk,
            spreadTRY: spreadTRY,
            spreadPercentage: spreadPercentage,
            bidVolumeTRY: bidVolumeTRY,
            askVolumeTRY: askVolumeTRY,
            bidPressureRatio: bidPressureRatio
        )
    }
}
