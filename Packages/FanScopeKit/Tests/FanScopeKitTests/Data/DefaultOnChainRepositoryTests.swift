import Foundation
import Testing
@testable import FanScopeKit

@Suite("DefaultOnChainRepository")
struct DefaultOnChainRepositoryTests {
    private let fixedNow = Date(timeIntervalSince1970: 1_795_300_000)

    private static let blockscoutTokenJSON = Data(#"""
    {
      "decimals": "6",
      "holders_count": "196",
      "total_supply": "41296676000000"
    }
    """#.utf8)

    private static let blockscoutTransfersJSON = Data(#"""
    {
      "items": [
        {
          "transaction_hash": "0xf75f2519",
          "log_index": 8,
          "timestamp": "2026-11-21T19:03:59.000000Z",
          "type": "token_transfer",
          "from": { "hash": "0xc80Afd311c9626528De66D86814770361Fe92416", "name": null, "metadata": null },
          "to": {
            "hash": "0xb334A61a6209F14b5fA5f1684a4eD7621f66e1eF",
            "name": null,
            "metadata": {
              "tags": [{ "name": "BtcTurk 17", "tagType": "name" }]
            }
          },
          "total": { "decimals": "6", "value": "3000000000" }
        },
        {
          "transaction_hash": "0xmint0001",
          "log_index": 1,
          "timestamp": "2026-11-18T12:00:00.000000Z",
          "type": "token_minting",
          "from": { "hash": "0x0000000000000000000000000000000000000000", "name": null, "metadata": null },
          "to": { "hash": "0x4879675Da42274a69F15f1cF969B2Cc6a455B7f9", "name": null, "metadata": null },
          "total": { "decimals": "6", "value": "500000000000" }
        }
      ]
    }
    """#.utf8)

    private static let blockscoutHoldersJSON = Data(#"""
    {
      "items": [
        {
          "address": { "hash": "0x4879675Da42274a69F15f1cF969B2Cc6a455B7f9", "name": null, "metadata": null },
          "value": "15466312000000"
        }
      ]
    }
    """#.utf8)

    private static let routescanSupplyJSON = Data(#"""
    { "status": "1", "message": "OK", "result": "9639243000000000000000000" }
    """#.utf8)

    private static let routescanHoldersJSON = Data(#"""
    {
      "items": [
        {
          "address": "0xc80Afd311c9626528De66D86814770361Fe92416",
          "balance": "3248966000000000000000000",
          "percentage": 0.337056
        }
      ]
    }
    """#.utf8)

    private static let routescanEmptyTxJSON = Data(#"""
    { "status": "0", "message": "No transactions found", "result": [] }
    """#.utf8)

    @Test("Routes Ethereum tokens to Blockscout and extracts labels, mints, and holder share")
    func fetchesEthereumSnapshot() async throws {
        let fb = try #require(TokenCatalog.token(forSymbol: "FB"))
        let stub = StubHTTPClient { endpoint in
            if endpoint.path.hasSuffix("/transfers") {
                return Self.blockscoutTransfersJSON
            } else if endpoint.path.hasSuffix("/holders") {
                return Self.blockscoutHoldersJSON
            } else {
                return Self.blockscoutTokenJSON
            }
        }

        let repository = DefaultOnChainRepository(httpClient: stub, now: { self.fixedNow })
        let snapshot = try await repository.fetchSnapshot(for: fb)

        #expect(snapshot.supply.totalSupply == 41_296_676.0)
        #expect(snapshot.supply.holdersCount == 196)
        #expect(snapshot.events.count == 2)

        let outflow = snapshot.events[0]
        #expect(outflow.kind == .exchangeOutflow)
        #expect(outflow.fromLabel == "Paribu Hot Wallet")
        #expect(outflow.toLabel == "BtcTurk 17")
        #expect(outflow.amount == 3_000.0)

        let mint = snapshot.events[1]
        #expect(mint.kind == .mint)
        #expect(mint.amount == 500_000.0)

        #expect(snapshot.monthlySummary.mintedAmount == 500_000.0)
        #expect(snapshot.monthlySummary.exchangeOutflowAmount == 3_000.0)

        let topHolder = try #require(snapshot.holders.first)
        #expect(topHolder.label == "FB Treasury Vault")
        let share = try #require(topHolder.sharePercentage)
        #expect(abs(share - 37.4517) < 0.01)
    }

    @Test("Routes Chiliz tokens to Routescan and normalizes holder percentages")
    func fetchesChilizSnapshot() async throws {
        let gal = try #require(TokenCatalog.token(forSymbol: "GAL"))
        let stub = StubHTTPClient { endpoint in
            if endpoint.path.hasSuffix("/holders") {
                return Self.routescanHoldersJSON
            }
            let action = endpoint.queryItems.first(where: { $0.name == "action" })?.value
            if action == "tokensupply" {
                return Self.routescanSupplyJSON
            }
            return Self.routescanEmptyTxJSON
        }

        let repository = DefaultOnChainRepository(httpClient: stub, now: { self.fixedNow })
        let snapshot = try await repository.fetchSnapshot(for: gal)

        #expect(snapshot.supply.totalSupply == 9_639_243.0)
        #expect(snapshot.events.isEmpty)

        let topHolder = try #require(snapshot.holders.first)
        #expect(topHolder.label == "Paribu Hot Wallet")
        #expect(abs((topHolder.sharePercentage ?? 0) - 33.7056) < 0.001)
    }

    @Test("Tolerates partial failure when one on-chain sub-request fails")
    func toleratesPartialFailure() async throws {
        let fb = try #require(TokenCatalog.token(forSymbol: "FB"))
        let stub = StubHTTPClient { endpoint in
            if endpoint.path.hasSuffix("/holders") {
                throw NetworkError.httpStatus(code: 503)
            } else if endpoint.path.hasSuffix("/transfers") {
                return Self.blockscoutTransfersJSON
            } else {
                return Self.blockscoutTokenJSON
            }
        }

        let repository = DefaultOnChainRepository(httpClient: stub, now: { self.fixedNow })
        let snapshot = try await repository.fetchSnapshot(for: fb)

        #expect(snapshot.supply.totalSupply == 41_296_676.0)
        #expect(snapshot.events.count == 2)
        #expect(snapshot.holders.isEmpty)
    }
}
