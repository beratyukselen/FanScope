import Foundation

public struct MarketTicker: Hashable, Sendable {
    public let lastPriceTRY: Decimal
    public let change24hTRY: Decimal
    public let changePercent24h: Double
    public let high24hTRY: Decimal
    public let low24hTRY: Decimal
    public let volumeToken24h: Double
    public let volumeTRY24h: Decimal

    public init(
        lastPriceTRY: Decimal,
        change24hTRY: Decimal,
        changePercent24h: Double,
        high24hTRY: Decimal,
        low24hTRY: Decimal,
        volumeToken24h: Double,
        volumeTRY24h: Decimal
    ) {
        self.lastPriceTRY = lastPriceTRY
        self.change24hTRY = change24hTRY
        self.changePercent24h = changePercent24h
        self.high24hTRY = high24hTRY
        self.low24hTRY = low24hTRY
        self.volumeToken24h = volumeToken24h
        self.volumeTRY24h = volumeTRY24h
    }
}

public struct SupplyMetrics: Hashable, Sendable {
    public let circulatingSupply: Double?
    public let totalSupply: Double?
    public let maxSupply: Double?
    public let holdersCount: Int?

    public init(
        circulatingSupply: Double? = nil,
        totalSupply: Double? = nil,
        maxSupply: Double? = nil,
        holdersCount: Int? = nil
    ) {
        self.circulatingSupply = circulatingSupply
        self.totalSupply = totalSupply
        self.maxSupply = maxSupply
        self.holdersCount = holdersCount
    }

    /// Fraction of supply currently in circulation relative to max or total supply, clamped to 0...1.
    public var circulatingRatio: Double? {
        guard let circulating = circulatingSupply, circulating >= 0 else { return nil }
        guard let denominator = maxSupply ?? totalSupply, denominator > 0 else { return nil }
        return min(max(circulating / denominator, 0), 1)
    }
}

public struct FanToken: Identifiable, Hashable, Sendable {
    public var id: String { definition.id }
    public let definition: TokenDefinition
    public let ticker: MarketTicker
    public let supply: SupplyMetrics?
    public let sparkline7dTRY: [Double]

    public init(
        definition: TokenDefinition,
        ticker: MarketTicker,
        supply: SupplyMetrics? = nil,
        sparkline7dTRY: [Double] = []
    ) {
        self.definition = definition
        self.ticker = ticker
        self.supply = supply
        self.sparkline7dTRY = sparkline7dTRY
    }
}
