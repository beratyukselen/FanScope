import Foundation
import Testing
@testable import FanScopeKit

@Suite("TokenCatalog")
struct TokenCatalogTests {
    @Test("Contains 35 Paribu fan tokens with unique symbols, markets, and valid contract addresses")
    func catalogIntegrity() {
        let tokens = TokenCatalog.all
        #expect(tokens.count == 35)

        let symbols = Set(tokens.map { $0.symbol.uppercased() })
        let markets = Set(tokens.map { $0.paribuMarket.lowercased() })
        let contracts = Set(tokens.map { $0.contractAddress.lowercased() })

        #expect(symbols.count == tokens.count)
        #expect(markets.count == tokens.count)
        #expect(contracts.count == tokens.count)

        for token in tokens {
            #expect(token.paribuMarket.hasSuffix("_tl"))
            #expect(token.contractAddress.hasPrefix("0x"))
            #expect(token.contractAddress.count == 42)
        }

        #expect(TokenCatalog.token(forSymbol: "SPAIN")?.paribuMarket == "spain_tl")
        #expect(TokenCatalog.token(forSymbol: "OM")?.paribuMarket == "om_tl")
        #expect(TokenCatalog.token(forSymbol: "SAM")?.category == .turkishClub)
        #expect(TokenCatalog.token(forSymbol: "FB")?.coinGeckoID == "fenerbahce-token")
    }

    @Test("Treats CoinGecko zero circulating supply as nil while preserving sparklines")
    func ignoresZeroCoinGeckoSupply() throws {
        let json = Data(#"""
        {
          "id": "fenerbahce-token",
          "symbol": "fb",
          "circulating_supply": 0.0,
          "total_supply": 41296676.0,
          "max_supply": 0.0,
          "sparkline_in_7d": { "price": [0.19, 0.20] }
        }
        """#.utf8)

        let dto = try JSONDecoder().decode(CoinGeckoMarketDTO.self, from: json)
        #expect(dto.supplyMetrics.circulatingSupply == nil)
        #expect(dto.supplyMetrics.totalSupply == 41_296_676.0)
        #expect(dto.supplyMetrics.maxSupply == nil)
        #expect(dto.sparklinePoints == [0.19, 0.20])
    }
}
