import FanScopeKit
import SwiftUI

struct TokenDetailView: View {
    @State private var viewModel: TokenDetailViewModel
    let watchlistViewModel: WatchlistViewModel
    let notifier: PriceTargetNotifier

    @State private var explorerDestination: ExplorerSheetDestination?
    @State private var isPresentingTargetSheet = false

    init(
        viewModel: TokenDetailViewModel,
        watchlistViewModel: WatchlistViewModel,
        notifier: PriceTargetNotifier
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.watchlistViewModel = watchlistViewModel
        self.notifier = notifier
    }

    private var token: FanToken { viewModel.token }
    private var movementColor: Color { AppColors.priceMovement(token.ticker.changePercent24h) }
    private var isWatched: Bool { watchlistViewModel.isWatched(token.definition.symbol) }
    private var existingEntry: WatchlistEntry? { watchlistViewModel.entry(for: token.definition.symbol) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                priceHeaderCard

                if let entry = existingEntry, let target = entry.targetPriceTRY {
                    activeTargetBanner(entry: entry, target: target)
                }

                InteractivePriceChartView(token: token)

                SupplyOverviewCard(
                    symbol: token.definition.symbol,
                    network: token.definition.network,
                    supply: viewModel.mergedSupply,
                    monthlySummary: viewModel.onChainState.value?.monthlySummary
                )

                OrderBookDepthView(
                    state: viewModel.orderBookState,
                    onRetry: {
                        Task { await viewModel.loadOrderBook() }
                    }
                )

                OnChainActivitySection(
                    symbol: token.definition.symbol,
                    network: token.definition.network,
                    state: viewModel.onChainState,
                    selectedTab: $viewModel.selectedOnChainTab,
                    selectedFilter: $viewModel.selectedFlowFilter,
                    filteredEvents: viewModel.filteredOnChainEvents,
                    onRetry: {
                        Task { await viewModel.loadOnChain(forceRefresh: true) }
                    },
                    onSelectURL: { url in
                        explorerDestination = ExplorerSheetDestination(url: url)
                    }
                )

                Text("detail.disclaimer")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 16)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .background(AppColors.surfaceBackground)
        .navigationTitle(token.definition.symbol)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    isPresentingTargetSheet = true
                } label: {
                    Image(systemName: existingEntry?.targetPriceTRY != nil ? "bell.badge.fill" : "bell")
                        .foregroundStyle(existingEntry?.targetPriceTRY != nil ? AppColors.accent : .primary)
                        .accessibilityLabel(Text("watchlist.sheet.title_edit"))
                }

                Button {
                    HapticFeedback.selection()
                    Task {
                        await watchlistViewModel.toggleWatch(symbol: token.definition.symbol)
                    }
                } label: {
                    Image(systemName: isWatched ? "star.fill" : "star")
                        .foregroundStyle(isWatched ? AppColors.warning : .primary)
                        .accessibilityLabel(Text("detail.toolbar.watch"))
                }

                if let contractURL = token.definition.network.addressURL(address: token.definition.contractAddress) {
                    Button {
                        explorerDestination = ExplorerSheetDestination(url: contractURL)
                    } label: {
                        Image(systemName: "safari")
                            .accessibilityLabel(Text("detail.toolbar.contract"))
                    }
                }
            }
        }
        .refreshable {
            HapticFeedback.lightImpact()
            await viewModel.loadAll(forceRefresh: true)
        }
        .task {
            await viewModel.loadAll()
        }
        .sheet(item: $explorerDestination) { destination in
            SafariExplorerView(url: destination.url)
                .ignoresSafeArea()
        }
        .sheet(isPresented: $isPresentingTargetSheet) {
            PriceTargetSheet(
                fixedSymbol: token.definition.symbol,
                currentPriceTRY: token.ticker.lastPriceTRY,
                existingEntry: existingEntry,
                onSave: { symbol, target, direction, note, wantsAlert in
                    Task {
                        if wantsAlert {
                            _ = await notifier.requestAuthorizationIfNeeded()
                        }
                        await watchlistViewModel.saveTarget(
                            symbol: symbol,
                            targetPriceTRY: target,
                            direction: direction,
                            note: note
                        )
                        await notifier.notifyReachedTargets(in: watchlistViewModel.rows)
                    }
                },
                onRemove: { symbol in
                    Task { await watchlistViewModel.remove(symbol: symbol) }
                }
            )
        }
    }

    private func activeTargetBanner(entry: WatchlistEntry, target: Decimal) -> some View {
        let status = PriceTargetEvaluator().evaluate(
            currentPriceTRY: token.ticker.lastPriceTRY,
            targetPriceTRY: target,
            direction: entry.targetDirection
        )
        let prefix = entry.targetDirection == .above ? "≥" : "≤"

        return Button {
            isPresentingTargetSheet = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: status?.isReached == true ? "checkmark.circle.fill" : "bell.fill")
                    .foregroundStyle(status?.isReached == true ? AppColors.positive : AppColors.accent)

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(prefix) \(FanScopeFormatter.tryPrice(target))")
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(.primary)

                    if !entry.note.isEmpty {
                        Text(entry.note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                if let status {
                    if status.isReached {
                        Text("watchlist.target.reached")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(AppColors.positive)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppColors.positive.opacity(0.14), in: Capsule())
                    } else {
                        Text(FanScopeFormatter.signedPercentage(status.distancePercentage))
                            .font(.caption.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(12)
            .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var priceHeaderCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ClubBadgeView(definition: token.definition, size: 48)

                VStack(alignment: .leading, spacing: 2) {
                    Text(token.definition.name)
                        .font(.title3.weight(.bold))
                    Text("\(token.definition.symbol) / TRY · \(token.definition.network.displayName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(FanScopeFormatter.tryPrice(token.ticker.lastPriceTRY))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .monospacedDigit()

                Text(FanScopeFormatter.signedPercentage(token.ticker.changePercent24h))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(movementColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(movementColor.opacity(0.14), in: Capsule())
            }

            HStack(spacing: 0) {
                compactStat(
                    title: "detail.stats.high_24h",
                    value: FanScopeFormatter.tryPrice(token.ticker.high24hTRY)
                )
                Divider().frame(height: 28)
                compactStat(
                    title: "detail.stats.low_24h",
                    value: FanScopeFormatter.tryPrice(token.ticker.low24hTRY)
                )
                Divider().frame(height: 28)
                compactStat(
                    title: "detail.stats.volume_24h",
                    value: FanScopeFormatter.compactTokenAmount(
                        NSDecimalNumber(decimal: token.ticker.volumeTRY24h).doubleValue
                    ) + " ₺"
                )
            }
            .padding(.top, 4)
        }
        .padding(16)
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func compactStat(title: LocalizedStringKey, value: String) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.weight(.semibold))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity)
    }
}
