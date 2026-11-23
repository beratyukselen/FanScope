import Foundation

public enum OnChainFlowKind: String, CaseIterable, Hashable, Sendable {
    case mint
    case burn
    case exchangeOutflow
    case exchangeInflow
    case exchangeInternal
    case transfer
}

public struct RawTokenTransfer: Hashable, Sendable {
    public let txHash: String
    public let logIndex: Int
    public let timestamp: Date
    public let fromAddress: String
    public let toAddress: String
    public let fromExternalLabel: String?
    public let toExternalLabel: String?
    public let amount: Double
    public let explicitType: String?
    public let network: BlockchainNetwork

    public init(
        txHash: String,
        logIndex: Int = 0,
        timestamp: Date,
        fromAddress: String,
        toAddress: String,
        fromExternalLabel: String? = nil,
        toExternalLabel: String? = nil,
        amount: Double,
        explicitType: String? = nil,
        network: BlockchainNetwork
    ) {
        self.txHash = txHash
        self.logIndex = logIndex
        self.timestamp = timestamp
        self.fromAddress = fromAddress
        self.toAddress = toAddress
        self.fromExternalLabel = fromExternalLabel
        self.toExternalLabel = toExternalLabel
        self.amount = amount
        self.explicitType = explicitType
        self.network = network
    }
}

public struct OnChainEvent: Identifiable, Hashable, Sendable {
    public let id: String
    public let txHash: String
    public let timestamp: Date
    public let kind: OnChainFlowKind
    public let amount: Double
    public let fromAddress: String
    public let fromLabel: String?
    public let toAddress: String
    public let toLabel: String?
    public let network: BlockchainNetwork

    public init(
        id: String,
        txHash: String,
        timestamp: Date,
        kind: OnChainFlowKind,
        amount: Double,
        fromAddress: String,
        fromLabel: String?,
        toAddress: String,
        toLabel: String?,
        network: BlockchainNetwork
    ) {
        self.id = id
        self.txHash = txHash
        self.timestamp = timestamp
        self.kind = kind
        self.amount = amount
        self.fromAddress = fromAddress
        self.fromLabel = fromLabel
        self.toAddress = toAddress
        self.toLabel = toLabel
        self.network = network
    }

    public var explorerURL: URL? {
        network.transactionURL(hash: txHash)
    }
}

public struct MonthlyFlowSummary: Hashable, Sendable {
    public let windowDays: Int
    public let mintedAmount: Double
    public let burnedAmount: Double
    public let exchangeOutflowAmount: Double
    public let exchangeInflowAmount: Double
    public let eventCount: Int

    public init(
        windowDays: Int = 30,
        mintedAmount: Double,
        burnedAmount: Double,
        exchangeOutflowAmount: Double,
        exchangeInflowAmount: Double,
        eventCount: Int
    ) {
        self.windowDays = windowDays
        self.mintedAmount = mintedAmount
        self.burnedAmount = burnedAmount
        self.exchangeOutflowAmount = exchangeOutflowAmount
        self.exchangeInflowAmount = exchangeInflowAmount
        self.eventCount = eventCount
    }

    public var netSupplyChange: Double {
        mintedAmount - burnedAmount
    }

    /// Positive means more tokens left the exchange (cold wallet accumulation); negative means net deposit to exchange.
    public var netExchangeOutflow: Double {
        exchangeOutflowAmount - exchangeInflowAmount
    }
}
