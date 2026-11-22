import Foundation

struct ParibuTickerDTO: Decodable, Sendable {
    let market: String
    let last: String
    let change: String
    let percentage: String
    let high: String
    let low: String
    let volume: String
    let pairVolume: String

    enum CodingKeys: String, CodingKey {
        case market
        case last
        case change
        case percentage
        case high
        case low
        case volume
        case pairVolume = "pair_volume"
    }

    func toDomain() -> MarketTicker? {
        guard let lastPrice = Decimal(string: last),
              let change24h = Decimal(string: change),
              let changePct = Double(percentage),
              let high24h = Decimal(string: high),
              let low24h = Decimal(string: low),
              let volumeToken = Double(volume),
              let volumeTRY = Decimal(string: pairVolume) else {
            return nil
        }

        return MarketTicker(
            lastPriceTRY: lastPrice,
            change24hTRY: change24h,
            changePercent24h: changePct,
            high24hTRY: high24h,
            low24hTRY: low24h,
            volumeToken24h: volumeToken,
            volumeTRY24h: volumeTRY
        )
    }
}

struct ParibuOrderBookDTO: Decodable, Sendable {
    let bids: [[String]]
    let asks: [[String]]

    func toDomain(market: String, fetchedAt: Date = Date()) -> OrderBook {
        OrderBook(
            market: market.lowercased(),
            bids: bids.compactMap(Self.parseLevel),
            asks: asks.compactMap(Self.parseLevel),
            fetchedAt: fetchedAt
        )
    }

    private static func parseLevel(_ pair: [String]) -> OrderBookLevel? {
        guard pair.count >= 2,
              let price = Decimal(string: pair[0]),
              let amount = Double(pair[1]) else {
            return nil
        }
        return OrderBookLevel(priceTRY: price, amount: amount)
    }
}
