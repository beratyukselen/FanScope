import Foundation

public enum PriceTargetDirection: String, CaseIterable, Codable, Hashable, Sendable {
    case above
    case below
}

public struct WatchlistEntry: Identifiable, Hashable, Sendable {
    public var id: String { symbol.lowercased() }
    public let symbol: String
    public let targetPriceTRY: Decimal?
    public let targetDirection: PriceTargetDirection
    public let note: String
    public let createdAt: Date

    public init(
        symbol: String,
        targetPriceTRY: Decimal? = nil,
        targetDirection: PriceTargetDirection = .above,
        note: String = "",
        createdAt: Date = Date()
    ) {
        self.symbol = symbol.uppercased()
        self.targetPriceTRY = targetPriceTRY
        self.targetDirection = targetDirection
        self.note = note
        self.createdAt = createdAt
    }
}

public protocol WatchlistRepositoryProtocol: Sendable {
    func fetchEntries() async throws -> [WatchlistEntry]
    func upsert(_ entry: WatchlistEntry) async throws
    func remove(symbol: String) async throws
}
