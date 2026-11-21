import Foundation

public struct OnChainSnapshot: Hashable, Sendable {
    public let supply: SupplyMetrics
    public let events: [OnChainEvent]
    public let holders: [TokenHolder]
    public let monthlySummary: MonthlyFlowSummary
    public let fetchedAt: Date

    public init(
        supply: SupplyMetrics,
        events: [OnChainEvent],
        holders: [TokenHolder],
        monthlySummary: MonthlyFlowSummary,
        fetchedAt: Date = Date()
    ) {
        self.supply = supply
        self.events = events
        self.holders = holders
        self.monthlySummary = monthlySummary
        self.fetchedAt = fetchedAt
    }
}

public protocol OnChainRepositoryProtocol: Sendable {
    func fetchSnapshot(for token: TokenDefinition, forceRefresh: Bool) async throws -> OnChainSnapshot
}
