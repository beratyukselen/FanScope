import Foundation

struct CoinGeckoMarketDTO: Decodable, Sendable {
    struct SparklineDTO: Decodable, Sendable {
        let price: [Double]?
    }

    let id: String
    let symbol: String
    let circulatingSupply: Double?
    let totalSupply: Double?
    let maxSupply: Double?
    let sparklineIn7d: SparklineDTO?

    enum CodingKeys: String, CodingKey {
        case id
        case symbol
        case circulatingSupply = "circulating_supply"
        case totalSupply = "total_supply"
        case maxSupply = "max_supply"
        case sparklineIn7d = "sparkline_in_7d"
    }

    var supplyMetrics: SupplyMetrics {
        SupplyMetrics(
            circulatingSupply: Self.positiveOrNil(circulatingSupply),
            totalSupply: Self.positiveOrNil(totalSupply),
            maxSupply: Self.positiveOrNil(maxSupply)
        )
    }

    var sparklinePoints: [Double] {
        sparklineIn7d?.price ?? []
    }

    private static func positiveOrNil(_ value: Double?) -> Double? {
        guard let value, value > 0 else { return nil }
        return value
    }
}
