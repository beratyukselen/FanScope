import Foundation

struct BlockscoutTokenDTO: Decodable, Sendable {
    let decimals: String?
    let holdersCount: String?
    let totalSupply: String?

    enum CodingKeys: String, CodingKey {
        case decimals
        case holdersCount = "holders_count"
        case totalSupply = "total_supply"
    }

    func toSupplyMetrics(fallbackDecimals: Int) -> SupplyMetrics {
        let resolvedDecimals = decimals.flatMap(Int.init) ?? fallbackDecimals
        let supply = totalSupply.flatMap { TokenAmountParser.parse(rawValue: $0, decimals: resolvedDecimals) }
        let holders = holdersCount.flatMap(Int.init)

        return SupplyMetrics(
            circulatingSupply: nil,
            totalSupply: supply,
            maxSupply: nil,
            holdersCount: holders
        )
    }
}

struct BlockscoutAddressDTO: Decodable, Sendable {
    struct MetadataDTO: Decodable, Sendable {
        struct TagDTO: Decodable, Sendable {
            let name: String
            let tagType: String?
        }

        let tags: [TagDTO]?
    }

    let hash: String
    let name: String?
    let metadata: MetadataDTO?

    var preferredLabel: String? {
        if let nameTag = metadata?.tags?.first(where: { $0.tagType == "name" })?.name, !nameTag.isEmpty {
            return nameTag
        }
        if let name, !name.isEmpty {
            return name
        }
        return nil
    }
}

struct BlockscoutTransfersResponseDTO: Decodable, Sendable {
    let items: [BlockscoutTransferDTO]
}

struct BlockscoutTransferDTO: Decodable, Sendable {
    struct TotalDTO: Decodable, Sendable {
        let decimals: String?
        let value: String
    }

    let transactionHash: String
    let logIndex: Int?
    let timestamp: String
    let type: String?
    let from: BlockscoutAddressDTO
    let to: BlockscoutAddressDTO
    let total: TotalDTO

    enum CodingKeys: String, CodingKey {
        case transactionHash = "transaction_hash"
        case logIndex = "log_index"
        case timestamp
        case type
        case from
        case to
        case total
    }

    func toRawTransfer(fallbackDecimals: Int, index: Int) -> RawTokenTransfer? {
        let resolvedDecimals = total.decimals.flatMap(Int.init) ?? fallbackDecimals
        guard let amount = TokenAmountParser.parse(rawValue: total.value, decimals: resolvedDecimals),
              let date = TokenAmountParser.parseISO8601(timestamp) else {
            return nil
        }

        return RawTokenTransfer(
            txHash: transactionHash,
            logIndex: logIndex ?? index,
            timestamp: date,
            fromAddress: from.hash,
            toAddress: to.hash,
            fromExternalLabel: from.preferredLabel,
            toExternalLabel: to.preferredLabel,
            amount: amount,
            explicitType: type,
            network: .ethereum
        )
    }
}

struct BlockscoutHoldersResponseDTO: Decodable, Sendable {
    let items: [BlockscoutHolderDTO]
}

struct BlockscoutHolderDTO: Decodable, Sendable {
    let address: BlockscoutAddressDTO
    let value: String

    func toDomain(decimals: Int, totalSupply: Double?) -> TokenHolder? {
        guard let balance = TokenAmountParser.parse(rawValue: value, decimals: decimals) else {
            return nil
        }
        let known = KnownWalletRegistry.wallet(for: address.hash)
        let sharePercentage: Double? = if let totalSupply, totalSupply > 0 {
            (balance / totalSupply) * 100.0
        } else {
            nil
        }

        return TokenHolder(
            address: address.hash,
            label: known?.label ?? address.preferredLabel,
            role: known?.role,
            balance: balance,
            sharePercentage: sharePercentage
        )
    }
}
