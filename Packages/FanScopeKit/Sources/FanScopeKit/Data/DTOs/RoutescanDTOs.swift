import Foundation

struct RoutescanSupplyResponseDTO: Decodable, Sendable {
    let status: String
    let result: String

    func parsedSupply(decimals: Int) -> Double? {
        guard status == "1" else { return nil }
        return TokenAmountParser.parse(rawValue: result, decimals: decimals)
    }
}

struct RoutescanHoldersResponseDTO: Decodable, Sendable {
    let items: [RoutescanHolderDTO]
}

struct RoutescanHolderDTO: Decodable, Sendable {
    let address: String
    let balance: String
    let percentage: Double?

    func toDomain(decimals: Int) -> TokenHolder? {
        guard let parsedBalance = TokenAmountParser.parse(rawValue: balance, decimals: decimals) else {
            return nil
        }
        let known = KnownWalletRegistry.wallet(for: address)
        // Routescan returns percentage as a 0...1 fraction (e.g. 0.337 -> 33.7%).
        let normalizedPercentage = percentage.map { $0 * 100.0 }

        return TokenHolder(
            address: address,
            label: known?.label,
            role: known?.role,
            balance: parsedBalance,
            sharePercentage: normalizedPercentage
        )
    }
}

struct RoutescanTokenTxResponseDTO: Decodable, Sendable {
    let status: String
    let transactions: [RoutescanTokenTxDTO]

    enum CodingKeys: String, CodingKey {
        case status
        case result
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.status = try container.decode(String.self, forKey: .status)
        // Etherscan-compatible endpoints return a string message in `result` when empty or rate-limited.
        if let list = try? container.decode([RoutescanTokenTxDTO].self, forKey: .result) {
            self.transactions = list
        } else {
            self.transactions = []
        }
    }
}

struct RoutescanTokenTxDTO: Decodable, Sendable {
    let hash: String
    let timeStamp: String
    let from: String
    let to: String
    let value: String
    let tokenDecimal: String?
    let logIndex: String?

    func toRawTransfer(fallbackDecimals: Int, index: Int) -> RawTokenTransfer? {
        let resolvedDecimals = tokenDecimal.flatMap(Int.init) ?? fallbackDecimals
        guard let amount = TokenAmountParser.parse(rawValue: value, decimals: resolvedDecimals),
              let date = TokenAmountParser.parseUnixTimestamp(timeStamp) else {
            return nil
        }

        return RawTokenTransfer(
            txHash: hash,
            logIndex: logIndex.flatMap(Int.init) ?? index,
            timestamp: date,
            fromAddress: from,
            toAddress: to,
            amount: amount,
            network: .chiliz
        )
    }
}
