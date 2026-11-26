import Foundation
import Observation

public enum MarketCategoryFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case turkishClubs
    case europeanClubs
    case nationalTeams
    case ecosystem

    public var id: String { rawValue }

    public func matches(_ category: TokenCategory) -> Bool {
        switch self {
        case .all:
            return true
        case .turkishClubs:
            return category == .turkishClub
        case .europeanClubs:
            return category == .europeanClub
        case .nationalTeams:
            return category == .nationalTeam
        case .ecosystem:
            return category == .ecosystem
        }
    }
}

public enum MarketSortOption: String, CaseIterable, Identifiable, Sendable {
    case featured
    case volumeDescending
    case gainersDescending
    case losersAscending
    case priceDescending

    public var id: String { rawValue }
}

@MainActor
@Observable
public final class MarketListViewModel {
    public private(set) var state: LoadState<[FanToken]> = .idle
    public private(set) var isRefreshing = false
    public private(set) var lastUpdatedAt: Date?

    public var searchText: String = "" {
        didSet {
            scheduleSearchDebounce(for: searchText)
        }
    }
    public private(set) var debouncedSearchText: String = ""
    public var selectedCategory: MarketCategoryFilter = .all
    public var sortOption: MarketSortOption = .featured

    private let marketRepository: any MarketRepositoryProtocol
    private let debounceNanoseconds: UInt64
    private let now: @Sendable () -> Date
    private var searchDebounceTask: Task<Void, Never>?

    public init(
        marketRepository: any MarketRepositoryProtocol,
        debounceNanoseconds: UInt64 = 250_000_000,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.marketRepository = marketRepository
        self.debounceNanoseconds = debounceNanoseconds
        self.now = now
    }

    public var allTokens: [FanToken] {
        state.value ?? []
    }

    public var filteredTokens: [FanToken] {
        let query = debouncedSearchText.trimmingCharacters(in: .whitespacesAndNewlines)

        let filtered = allTokens.filter { token in
            guard selectedCategory.matches(token.definition.category) else {
                return false
            }
            guard !query.isEmpty else {
                return true
            }
            return token.definition.symbol.localizedCaseInsensitiveContains(query)
                || token.definition.name.localizedCaseInsensitiveContains(query)
        }

        switch sortOption {
        case .featured:
            return filtered
        case .volumeDescending:
            return filtered.sorted { $0.ticker.volumeTRY24h > $1.ticker.volumeTRY24h }
        case .gainersDescending:
            return filtered.sorted { $0.ticker.changePercent24h > $1.ticker.changePercent24h }
        case .losersAscending:
            return filtered.sorted { $0.ticker.changePercent24h < $1.ticker.changePercent24h }
        case .priceDescending:
            return filtered.sorted { $0.ticker.lastPriceTRY > $1.ticker.lastPriceTRY }
        }
    }

    public var totalVolumeTRY24h: Decimal {
        allTokens.reduce(Decimal.zero) { $0 + $1.ticker.volumeTRY24h }
    }

    public var topGainer: FanToken? {
        allTokens.max { $0.ticker.changePercent24h < $1.ticker.changePercent24h }
    }

    public func load(forceRefresh: Bool = false) async {
        let hasExistingData = state.value != nil
        if hasExistingData {
            isRefreshing = true
        } else {
            state = .loading
        }
        defer { isRefreshing = false }

        do {
            let tokens = try await marketRepository.fetchFanTokens(forceRefresh: forceRefresh)
            state = tokens.isEmpty ? .empty : .loaded(tokens)
            lastUpdatedAt = now()
        } catch is CancellationError {
            return
        } catch {
            if !hasExistingData {
                state = .failed(error.localizedDescription)
            }
        }
    }

    /// Background polling refresh that keeps existing market data intact on transient failures.
    public func refreshSilently() async {
        do {
            let tokens = try await marketRepository.fetchFanTokens(forceRefresh: true)
            guard !tokens.isEmpty else { return }
            state = .loaded(tokens)
            lastUpdatedAt = now()
        } catch {
            return
        }
    }

    private func scheduleSearchDebounce(for query: String) {
        searchDebounceTask?.cancel()

        if debounceNanoseconds == 0 || query.isEmpty {
            debouncedSearchText = query
            return
        }

        let delay = debounceNanoseconds
        searchDebounceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: delay)
            guard !Task.isCancelled else { return }
            self?.debouncedSearchText = query
        }
    }
}
