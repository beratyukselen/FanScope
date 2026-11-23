import FanScopeKit
import SwiftUI

struct MarketListView: View {
    @State private var viewModel: MarketListViewModel
    private let container: AppContainer
    @Environment(\.scenePhase) private var scenePhase

    init(container: AppContainer) {
        self.container = container
        self._viewModel = State(initialValue: container.makeMarketListViewModel())
    }

    var body: some View {
        NavigationStack {
            LoadStateView(
                state: viewModel.state,
                emptyTitle: "markets.empty.title",
                emptySystemImage: "chart.bar.xaxis",
                emptyDescription: "markets.empty.description",
                onRetry: {
                    Task { await viewModel.load(forceRefresh: true) }
                }
            ) { _ in
                marketListContent
            }
            .background(AppColors.surfaceBackground)
            .navigationTitle("FanScope")
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: Text("markets.search.prompt")
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    sortMenu
                }
                ToolbarItem(placement: .topBarTrailing) {
                    LanguageMenuButton()
                }
            }
            .navigationDestination(for: FanToken.self) { token in
                TokenDetailView(
                    viewModel: container.makeTokenDetailViewModel(for: token)
                )
            }
            .task {
                if case .idle = viewModel.state {
                    await viewModel.load()
                }
            }
            .task(id: scenePhase) {
                guard scenePhase == .active else { return }
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(15))
                    guard !Task.isCancelled else { break }
                    await viewModel.refreshSilently()
                }
            }
        }
    }

    private var marketListContent: some View {
        List {
            Section {
                marketSummaryStrip
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                categoryFilterStrip
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 4, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            if viewModel.filteredTokens.isEmpty {
                Section {
                    ContentUnavailableView.search(text: viewModel.searchText)
                        .listRowBackground(Color.clear)
                }
            } else {
                Section {
                    ForEach(viewModel.filteredTokens) { token in
                        NavigationLink(value: token) {
                            TokenRowView(token: token)
                        }
                    }
                } header: {
                    HStack {
                        Text("markets.section.tokens")
                        Spacer()
                        if let updated = viewModel.lastUpdatedAt {
                            Text(updated, format: .dateTime.hour().minute().second())
                                .font(.caption2)
                                .monospacedDigit()
                                .foregroundStyle(.tertiary)
                        }
                    }
                } footer: {
                    Text("markets.footer.source")
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            HapticFeedback.lightImpact()
            await viewModel.load(forceRefresh: true)
        }
    }

    private var marketSummaryStrip: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("markets.summary.volume_24h")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(FanScopeFormatter.compactTokenAmount(
                    NSDecimalNumber(decimal: viewModel.totalVolumeTRY24h).doubleValue
                ) + " ₺")
                    .font(.headline.weight(.bold))
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            if let leader = viewModel.topGainer {
                let color = AppColors.priceMovement(leader.ticker.changePercent24h)
                VStack(alignment: .leading, spacing: 4) {
                    Text("markets.summary.top_mover")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack(spacing: 6) {
                        Text(leader.definition.symbol)
                            .font(.headline.weight(.bold))
                        Text(FanScopeFormatter.signedPercentage(leader.ticker.changePercent24h))
                            .font(.caption.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(color)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private var categoryFilterStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MarketCategoryFilter.allCases) { category in
                    let isSelected = viewModel.selectedCategory == category
                    Button {
                        HapticFeedback.selection()
                        viewModel.selectedCategory = category
                    } label: {
                        Text(category.localizedTitleKey)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .foregroundStyle(isSelected ? .white : .primary)
                            .background(
                                isSelected ? AppColors.accent : AppColors.cardBackground,
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var sortMenu: some View {
        Menu {
            Picker("markets.sort.title", selection: $viewModel.sortOption) {
                ForEach(MarketSortOption.allCases) { option in
                    Text(option.localizedTitleKey)
                        .tag(option)
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down.circle")
                .accessibilityLabel(Text("markets.sort.title"))
        }
    }
}

private extension MarketCategoryFilter {
    var localizedTitleKey: LocalizedStringKey {
        switch self {
        case .all: return "markets.filter.all"
        case .turkishClubs: return "markets.filter.turkish"
        case .europeanClubs: return "markets.filter.european"
        case .nationalTeams: return "markets.filter.national"
        case .ecosystem: return "markets.filter.ecosystem"
        }
    }
}

private extension MarketSortOption {
    var localizedTitleKey: LocalizedStringKey {
        switch self {
        case .featured: return "markets.sort.featured"
        case .volumeDescending: return "markets.sort.volume"
        case .gainersDescending: return "markets.sort.gainers"
        case .losersAscending: return "markets.sort.losers"
        case .priceDescending: return "markets.sort.price"
        }
    }
}
