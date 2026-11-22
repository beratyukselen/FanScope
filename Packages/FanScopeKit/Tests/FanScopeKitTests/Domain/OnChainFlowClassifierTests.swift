import Foundation
import Testing
@testable import FanScopeKit

@Suite("OnChainFlowClassifier")
struct OnChainFlowClassifierTests {
    private let classifier = OnChainFlowClassifier()
    private let referenceDate = Date(timeIntervalSince1970: 1_795_200_000)

    @Test("Classifies zero-address sender as mint")
    func classifiesMintByNullSender() {
        let raw = RawTokenTransfer(
            txHash: "0xabc",
            timestamp: referenceDate,
            fromAddress: KnownWalletRegistry.nullAddress,
            toAddress: "0x159e50de11111111111111111111111111111111",
            amount: 3_681_818,
            network: .ethereum
        )

        let event = classifier.classify(raw)
        #expect(event.kind == .mint)
        #expect(event.fromLabel == "Null Address")
    }

    @Test("Classifies zero-address recipient as burn")
    func classifiesBurnByNullRecipient() {
        let raw = RawTokenTransfer(
            txHash: "0xdef",
            timestamp: referenceDate,
            fromAddress: "0x4879675Da42274a69F15f1cF969B2Cc6a455B7f9",
            toAddress: KnownWalletRegistry.nullAddress,
            amount: 500_000,
            network: .ethereum
        )

        let event = classifier.classify(raw)
        #expect(event.kind == .burn)
        #expect(event.fromLabel == "FB Treasury Vault")
    }

    @Test("Classifies exchange hot wallet to cold reserve as exchangeOutflow")
    func classifiesExchangeOutflow() {
        let raw = RawTokenTransfer(
            txHash: "0x111",
            timestamp: referenceDate,
            fromAddress: "0xc80Afd311c9626528De66D86814770361Fe92416",
            toAddress: "0x76eC5A0D3632b2133d9f1980903305B62678Fbd3",
            amount: 250_000,
            network: .chiliz
        )

        let event = classifier.classify(raw)
        #expect(event.kind == .exchangeOutflow)
        #expect(event.fromLabel == "Paribu Hot Wallet")
        #expect(event.toLabel == "Paribu Cold Reserve 1")
    }

    @Test("Classifies external transfer into exchange hot wallet as exchangeInflow")
    func classifiesExchangeInflow() {
        let raw = RawTokenTransfer(
            txHash: "0x222",
            timestamp: referenceDate,
            fromAddress: "0x4Fa8430A00000000000000000000000000000000",
            toAddress: "0xc80Afd311c9626528De66D86814770361Fe92416",
            amount: 1_999_999,
            network: .ethereum
        )

        let event = classifier.classify(raw)
        #expect(event.kind == .exchangeInflow)
        #expect(event.toLabel == "Paribu Hot Wallet")
    }

    @Test("Summarizes flows strictly within the 30-day lookback window")
    func summarizesRecentWindow() {
        let recentMint = classifier.classify(
            RawTokenTransfer(
                txHash: "0x1",
                timestamp: referenceDate.addingTimeInterval(-5 * 86_400),
                fromAddress: KnownWalletRegistry.nullAddress,
                toAddress: "0x159e50de",
                amount: 1_000_000,
                network: .ethereum
            )
        )
        let recentOutflow = classifier.classify(
            RawTokenTransfer(
                txHash: "0x2",
                timestamp: referenceDate.addingTimeInterval(-2 * 86_400),
                fromAddress: KnownWalletRegistry.primaryExchangeHotWallet,
                toAddress: "0x76eC5A0D3632b2133d9f1980903305B62678Fbd3",
                amount: 400_000,
                network: .ethereum
            )
        )
        let recentInflow = classifier.classify(
            RawTokenTransfer(
                txHash: "0x3",
                timestamp: referenceDate.addingTimeInterval(-1 * 86_400),
                fromAddress: "0x1111111111111111111111111111111111111111",
                toAddress: KnownWalletRegistry.primaryExchangeHotWallet,
                amount: 150_000,
                network: .ethereum
            )
        )
        let staleMint = classifier.classify(
            RawTokenTransfer(
                txHash: "0x4",
                timestamp: referenceDate.addingTimeInterval(-45 * 86_400),
                fromAddress: KnownWalletRegistry.nullAddress,
                toAddress: "0x159e50de",
                amount: 9_000_000,
                network: .ethereum
            )
        )

        let summary = classifier.summarize(
            [recentMint, recentOutflow, recentInflow, staleMint],
            windowDays: 30,
            referenceDate: referenceDate
        )

        #expect(summary.eventCount == 3)
        #expect(summary.mintedAmount == 1_000_000)
        #expect(summary.burnedAmount == 0)
        #expect(summary.netSupplyChange == 1_000_000)
        #expect(summary.exchangeOutflowAmount == 400_000)
        #expect(summary.exchangeInflowAmount == 150_000)
        #expect(summary.netExchangeOutflow == 250_000)
    }
}
