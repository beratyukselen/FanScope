import Foundation
import OSLog

public final class DefaultOnChainRepository: OnChainRepositoryProtocol {
    private let httpClient: any HTTPClientProtocol
    private let classifier: OnChainFlowClassifier
    private let snapshotCache: TTLCache<String, OnChainSnapshot>
    private let snapshotTTL: TimeInterval
    private let now: @Sendable () -> Date

    public init(
        httpClient: any HTTPClientProtocol,
        classifier: OnChainFlowClassifier = OnChainFlowClassifier(),
        snapshotTTL: TimeInterval = 60,
        now: @escaping @Sendable () -> Date = Date.init
    ) {
        self.httpClient = httpClient
        self.classifier = classifier
        self.snapshotTTL = snapshotTTL
        self.now = now
        self.snapshotCache = TTLCache(now: now)
    }

    public func fetchSnapshot(
        for token: TokenDefinition,
        forceRefresh: Bool = false
    ) async throws -> OnChainSnapshot {
        let cacheKey = "\(token.network.rawValue):\(token.contractAddress.lowercased())"
        if !forceRefresh, let cached = await snapshotCache.value(for: cacheKey) {
            return cached
        }

        let snapshot: OnChainSnapshot
        do {
            switch token.network {
            case .ethereum:
                snapshot = try await fetchEthereumSnapshot(for: token)
            case .chiliz:
                snapshot = try await fetchChilizSnapshot(for: token)
            }
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            if let stale = await snapshotCache.staleValue(for: cacheKey) {
                AppLogger.onChain.warning(
                    "On-chain refresh failed for \(token.symbol, privacy: .public); serving stale snapshot"
                )
                return stale
            }
            throw error
        }

        await snapshotCache.insert(snapshot, for: cacheKey, ttl: snapshotTTL)
        return snapshot
    }

    private func fetchEthereumSnapshot(for token: TokenDefinition) async throws -> OnChainSnapshot {
        let contract = token.contractAddress

        async let infoResult = captureResult {
            try await self.httpClient.send(FanScopeEndpoints.Blockscout.tokenInfo(contract: contract)) as BlockscoutTokenDTO
        }
        async let transfersResult = captureResult {
            try await self.httpClient.send(FanScopeEndpoints.Blockscout.tokenTransfers(contract: contract)) as BlockscoutTransfersResponseDTO
        }
        async let holdersResult = captureResult {
            try await self.httpClient.send(FanScopeEndpoints.Blockscout.tokenHolders(contract: contract)) as BlockscoutHoldersResponseDTO
        }

        let (info, transfers, holders) = (
            try await infoResult,
            try await transfersResult,
            try await holdersResult
        )

        if case .failure(let primaryError) = info,
           case .failure = transfers,
           case .failure = holders {
            throw primaryError
        }

        let supply = (try? info.get())?.toSupplyMetrics(fallbackDecimals: token.decimals) ?? SupplyMetrics()
        let rawTransfers = (try? transfers.get())?.items.enumerated().compactMap { index, dto in
            dto.toRawTransfer(fallbackDecimals: token.decimals, index: index)
        } ?? []

        let events = rawTransfers
            .map(classifier.classify)
            .sorted { $0.timestamp > $1.timestamp }

        let resolvedHolders = (try? holders.get())?.items.compactMap { dto in
            dto.toDomain(decimals: token.decimals, totalSupply: supply.totalSupply)
        } ?? []

        let referenceDate = now()
        let summary = classifier.summarize(events, windowDays: 30, referenceDate: referenceDate)

        return OnChainSnapshot(
            supply: supply,
            events: events,
            holders: Array(resolvedHolders.prefix(10)),
            monthlySummary: summary,
            fetchedAt: referenceDate
        )
    }

    private func fetchChilizSnapshot(for token: TokenDefinition) async throws -> OnChainSnapshot {
        let contract = token.contractAddress

        async let supplyResult = captureResult {
            try await self.httpClient.send(FanScopeEndpoints.Routescan.tokenSupply(contract: contract)) as RoutescanSupplyResponseDTO
        }
        async let holdersResult = captureResult {
            try await self.httpClient.send(FanScopeEndpoints.Routescan.tokenHolders(contract: contract, limit: 10)) as RoutescanHoldersResponseDTO
        }
        async let transfersResult = captureResult {
            try await self.httpClient.send(
                FanScopeEndpoints.Routescan.addressTokenTransfers(
                    contract: contract,
                    address: KnownWalletRegistry.primaryExchangeHotWallet,
                    limit: 25
                )
            ) as RoutescanTokenTxResponseDTO
        }

        let (supplyRes, holdersRes, transfersRes) = (
            try await supplyResult,
            try await holdersResult,
            try await transfersResult
        )

        if case .failure(let primaryError) = supplyRes,
           case .failure = holdersRes,
           case .failure = transfersRes {
            throw primaryError
        }

        let parsedSupply = (try? supplyRes.get())?.parsedSupply(decimals: token.decimals)
        let supply = SupplyMetrics(totalSupply: parsedSupply)

        let resolvedHolders = (try? holdersRes.get())?.items.compactMap { dto in
            dto.toDomain(decimals: token.decimals)
        } ?? []

        let rawTransfers = (try? transfersRes.get())?.transactions.enumerated().compactMap { index, dto in
            dto.toRawTransfer(fallbackDecimals: token.decimals, index: index)
        } ?? []

        let events = rawTransfers
            .map(classifier.classify)
            .sorted { $0.timestamp > $1.timestamp }

        let referenceDate = now()
        let summary = classifier.summarize(events, windowDays: 30, referenceDate: referenceDate)

        return OnChainSnapshot(
            supply: supply,
            events: events,
            holders: resolvedHolders,
            monthlySummary: summary,
            fetchedAt: referenceDate
        )
    }

    private func captureResult<T: Sendable>(
        _ operation: () async throws -> T
    ) async throws -> Result<T, Error> {
        do {
            return .success(try await operation())
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            AppLogger.onChain.warning("Partial on-chain request failed: \(error.localizedDescription, privacy: .public)")
            return .failure(error)
        }
    }
}
