import Foundation

public struct OrderBookLevel: Hashable, Sendable {
    public let priceTRY: Decimal
    public let amount: Double

    public init(priceTRY: Decimal, amount: Double) {
        self.priceTRY = priceTRY
        self.amount = amount
    }

    public var totalTRY: Decimal {
        priceTRY * Decimal(amount)
    }
}

public struct OrderBook: Hashable, Sendable {
    public let market: String
    public let bids: [OrderBookLevel]
    public let asks: [OrderBookLevel]
    public let fetchedAt: Date

    public init(
        market: String,
        bids: [OrderBookLevel],
        asks: [OrderBookLevel],
        fetchedAt: Date = Date()
    ) {
        self.market = market
        self.bids = bids
        self.asks = asks
        self.fetchedAt = fetchedAt
    }
}

public struct OrderBookSummary: Hashable, Sendable {
    public let bestBid: Decimal?
    public let bestAsk: Decimal?
    public let spreadTRY: Decimal?
    public let spreadPercentage: Double?
    public let bidVolumeTRY: Decimal
    public let askVolumeTRY: Decimal
    public let bidPressureRatio: Double

    public init(
        bestBid: Decimal?,
        bestAsk: Decimal?,
        spreadTRY: Decimal?,
        spreadPercentage: Double?,
        bidVolumeTRY: Decimal,
        askVolumeTRY: Decimal,
        bidPressureRatio: Double
    ) {
        self.bestBid = bestBid
        self.bestAsk = bestAsk
        self.spreadTRY = spreadTRY
        self.spreadPercentage = spreadPercentage
        self.bidVolumeTRY = bidVolumeTRY
        self.askVolumeTRY = askVolumeTRY
        self.bidPressureRatio = bidPressureRatio
    }
}
