import Foundation

public struct OnChainFlowClassifier: Sendable {
    public init() {}

    public func classify(_ transfer: RawTokenTransfer) -> OnChainEvent {
        let normalizedFrom = transfer.fromAddress.lowercased()
        let normalizedTo = transfer.toAddress.lowercased()

        let fromWallet = KnownWalletRegistry.wallet(for: normalizedFrom)
        let toWallet = KnownWalletRegistry.wallet(for: normalizedTo)

        let kind = resolveKind(
            explicitType: transfer.explicitType,
            fromAddress: normalizedFrom,
            toAddress: normalizedTo,
            fromRole: fromWallet?.role,
            toRole: toWallet?.role
        )

        return OnChainEvent(
            id: "\(transfer.txHash.lowercased())-\(transfer.logIndex)",
            txHash: transfer.txHash,
            timestamp: transfer.timestamp,
            kind: kind,
            amount: transfer.amount,
            fromAddress: transfer.fromAddress,
            fromLabel: fromWallet?.label,
            toAddress: transfer.toAddress,
            toLabel: toWallet?.label,
            network: transfer.network
        )
    }

    public func summarize(
        _ events: [OnChainEvent],
        windowDays: Int = 30,
        referenceDate: Date = Date()
    ) -> MonthlyFlowSummary {
        let cutoff = referenceDate.addingTimeInterval(-TimeInterval(windowDays * 86_400))
        let inWindow = events.filter { $0.timestamp >= cutoff && $0.timestamp <= referenceDate }

        var minted = 0.0
        var burned = 0.0
        var outflow = 0.0
        var inflow = 0.0

        for event in inWindow {
            switch event.kind {
            case .mint:
                minted += event.amount
            case .burn:
                burned += event.amount
            case .exchangeOutflow:
                outflow += event.amount
            case .exchangeInflow:
                inflow += event.amount
            case .exchangeInternal, .transfer:
                break
            }
        }

        return MonthlyFlowSummary(
            windowDays: windowDays,
            mintedAmount: minted,
            burnedAmount: burned,
            exchangeOutflowAmount: outflow,
            exchangeInflowAmount: inflow,
            eventCount: inWindow.count
        )
    }

    private func resolveKind(
        explicitType: String?,
        fromAddress: String,
        toAddress: String,
        fromRole: WalletRole?,
        toRole: WalletRole?
    ) -> OnChainFlowKind {
        if explicitType == "token_minting" || fromAddress == KnownWalletRegistry.nullAddress {
            return .mint
        }
        if explicitType == "token_burning" || toAddress == KnownWalletRegistry.nullAddress {
            return .burn
        }

        switch (fromRole, toRole) {
        case (.exchangeHot, .exchangeHot):
            return .exchangeInternal
        case (.exchangeHot, _):
            return .exchangeOutflow
        case (_, .exchangeHot):
            return .exchangeInflow
        default:
            return .transfer
        }
    }
}
