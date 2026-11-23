import FanScopeKit
import SwiftUI

struct TokenDetailView: View {
    @State private var viewModel: TokenDetailViewModel
    @State private var explorerDestination: ExplorerSheetDestination?

    init(viewModel: TokenDetailViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    private var token: FanToken { viewModel.token }
    private var movementColor: Color { AppColors.priceMovement(token.ticker.changePercent24h) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                priceHeaderCard

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
            ToolbarItem(placement: .topBarTrailing) {
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
