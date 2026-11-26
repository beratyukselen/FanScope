import Foundation
import Observation
import OSLog

public struct WatchlistItemRow: Identifiable, Hashable, Sendable {
    public var id: String { entry.id }
    public let entry: WatchlistEntry
    public let definition: TokenDefinition?
    public let token: FanToken?
    public let targetStatus: PriceTargetStatus?

    public init(
        entry: WatchlistEntry,
        definition: TokenDefinition?,
        token: FanToken?,
        targetStatus: PriceTargetStatus?
    ) {
        self.entry = entry
        self.definition = definition
        self.token = token
        self.targetStatus = targetStatus
    }
}

@MainActor
@Observable
public final class WatchlistViewModel {
    public private(set) var state: LoadState<[WatchlistItemRow]> = .idle
    public private(set) var entriesBySymbol: [String: WatchlistEntry] = [:]
    public private(set) var lastUpdatedAt: Date?

    private let watchlistRepository: any WatchlistRepositoryProtocol
    private let marketRepository: any MarketRepositoryProtocol
    private let evaluator: PriceTargetEvaluator
    private let now: @Sendable () -> Date

    public init(
        watchlistRepository: any WatchlistRepositoryProtocol,
        marketRepository: any MarketRepositoryProtocol,
        evaluator: PriceTargetEvaluator = PriceTargetEvaluator(),
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.watchlistRepository = watchlistRepository
        self.marketRepository = marketRepository
        self.evaluator = evaluator
        self.now = now
    }

    public var rows: [WatchlistItemRow] {
        state.value ?? []
    }

    public var reachedTargetCount: Int {
        rows.filter { $0.targetStatus?.isReached == true }.count
    }

    public func isWatched(_ symbol: String) -> Bool {
        entriesBySymbol[symbol.uppercased()] != nil
    }

    public func entry(for symbol: String) -> WatchlistEntry? {
        entriesBySymbol[symbol.uppercased()]
    }

    public func load(forceRefresh: Bool = false) async {
        if state.value == nil {
            state = .loading
        }

        do {
            async let entriesTask = watchlistRepository.fetchEntries()
            async let tokensTask = fetchMarketTokensSafely(forceRefresh: forceRefresh)

            let entries = try await entriesTask
            let tokensBySymbol = try await tokensTask

            apply(entries: entries, tokensBySymbol: tokensBySymbol)
            lastUpdatedAt = now()
        } catch is CancellationError {
            return
        } catch {
            if state.value == nil {
                state = .failed(error.localizedDescription)
            }
        }
    }

    public func toggleWatch(symbol: String) async {
        let normalized = symbol.uppercased()
        if isWatched(normalized) {
            await remove(symbol: normalized)
        } else {
            let entry = WatchlistEntry(symbol: normalized, createdAt: now())
            await upsertAndReload(entry)
        }
    }

    public func saveTarget(
        symbol: String,
        targetPriceTRY: Decimal?,
        direction: PriceTargetDirection,
        note: String
    ) async {
        let normalized = symbol.uppercased()
        let existingCreatedAt = entriesBySymbol[normalized]?.createdAt ?? now()
        let cleanedNote = note.trimmingCharacters(in: .whitespacesAndNewlines)

        let entry = WatchlistEntry(
            symbol: normalized,
            targetPriceTRY: targetPriceTRY,
            targetDirection: direction,
            note: cleanedNote,
            createdAt: existingCreatedAt
        )
        await upsertAndReload(entry)
    }

    public func remove(symbol: String) async {
        let normalized = symbol.uppercased()
        do {
            try await watchlistRepository.remove(symbol: normalized)
            await load(forceRefresh: false)
        } catch {
            AppLogger.persistence.error(
                "Failed to remove \(normalized, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    private func upsertAndReload(_ entry: WatchlistEntry) async {
        do {
            try await watchlistRepository.upsert(entry)
            await load(forceRefresh: false)
        } catch {
            AppLogger.persistence.error(
                "Failed to save \(entry.symbol, privacy: .public): \(error.localizedDescription, privacy: .public)"
            )
        }
    }

    /// Keeps saved watchlist items usable offline if the upstream market API fails.
    private func fetchMarketTokensSafely(forceRefresh: Bool) async throws -> [String: FanToken] {
        do {
            let tokens = try await marketRepository.fetchFanTokens(forceRefresh: forceRefresh)
            return Dictionary(
                tokens.map { ($0.definition.symbol.uppercased(), $0) },
                uniquingKeysWith: { first, _ in first }
            )
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            AppLogger.network.warning("Watchlist market enrichment failed; rendering offline entries")
            return [:]
        }
    }

    private func apply(entries: [WatchlistEntry], tokensBySymbol: [String: FanToken]) {
        let sortedEntries = entries.sorted { $0.createdAt > $1.createdAt }
        entriesBySymbol = Dictionary(
            uniqueKeysWithValues: sortedEntries.map { ($0.symbol.uppercased(), $0) }
        )

        guard !sortedEntries.isEmpty else {
            state = .empty
            return
        }

        let builtRows = sortedEntries.map { entry -> WatchlistItemRow in
            let symbol = entry.symbol.uppercased()
            let token = tokensBySymbol[symbol]
            let definition = token?.definition ?? TokenCatalog.token(forSymbol: symbol)
            let status: PriceTargetStatus? = if let token, let target = entry.targetPriceTRY {
                evaluator.evaluate(
                    currentPriceTRY: token.ticker.lastPriceTRY,
                    targetPriceTRY: target,
                    direction: entry.targetDirection
                )
            } else {
                nil
            }

            return WatchlistItemRow(
                entry: entry,
                definition: definition,
                token: token,
                targetStatus: status
            )
        }

        state = .loaded(builtRows)
    }
}
