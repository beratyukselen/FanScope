import FanScopeKit
import SwiftUI

struct WatchlistView: View {
    let container: AppContainer
    @State private var isPresentingAddSheet = false
    @State private var editingRow: WatchlistItemRow?

    private var viewModel: WatchlistViewModel {
        container.watchlistViewModel
    }

    var body: some View {
        NavigationStack {
            LoadStateView(
                state: viewModel.state,
                emptyTitle: "watchlist.empty.title",
                emptySystemImage: "star.slash",
                emptyDescription: "watchlist.empty.description",
                onRetry: {
                    Task { await viewModel.load(forceRefresh: true) }
                }
            ) { rows in
                watchlistContent(rows)
            }
            .background(AppColors.surfaceBackground)
            .navigationTitle("tab.watchlist")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isPresentingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .accessibilityLabel(Text("watchlist.sheet.title_add"))
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    LanguageMenuButton()
                }
            }
            .navigationDestination(for: FanToken.self) { token in
                TokenDetailView(
                    viewModel: container.makeTokenDetailViewModel(for: token),
                    watchlistViewModel: viewModel,
                    notifier: container.priceTargetNotifier
                )
            }
            .sheet(isPresented: $isPresentingAddSheet) {
                PriceTargetSheet(
                    onSave: { symbol, target, direction, note, wantsAlert in
                        Task {
                            if wantsAlert {
                                _ = await container.priceTargetNotifier.requestAuthorizationIfNeeded()
                            }
                            await viewModel.saveTarget(
                                symbol: symbol,
                                targetPriceTRY: target,
                                direction: direction,
                                note: note
                            )
                            await container.priceTargetNotifier.notifyReachedTargets(in: viewModel.rows)
                        }
                    }
                )
            }
            .sheet(item: $editingRow) { row in
                PriceTargetSheet(
                    fixedSymbol: row.entry.symbol,
                    currentPriceTRY: row.token?.ticker.lastPriceTRY,
                    existingEntry: row.entry,
                    onSave: { symbol, target, direction, note, wantsAlert in
                        Task {
                            if wantsAlert {
                                _ = await container.priceTargetNotifier.requestAuthorizationIfNeeded()
                            }
                            await viewModel.saveTarget(
                                symbol: symbol,
                                targetPriceTRY: target,
                                direction: direction,
                                note: note
                            )
                            await container.priceTargetNotifier.notifyReachedTargets(in: viewModel.rows)
                        }
                    },
                    onRemove: { symbol in
                        Task { await viewModel.remove(symbol: symbol) }
                    }
                )
            }
            .task {
                await viewModel.load()
                await container.priceTargetNotifier.notifyReachedTargets(in: viewModel.rows)
            }
        }
    }

    private func watchlistContent(_ rows: [WatchlistItemRow]) -> some View {
        List {
            Section {
                summaryStrip(total: rows.count, reached: viewModel.reachedTargetCount)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            Section("watchlist.section.tracked") {
                ForEach(rows) { row in
                    if let token = row.token {
                        NavigationLink(value: token) {
                            watchlistRowView(row)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task { await viewModel.remove(symbol: row.entry.symbol) }
                            } label: {
                                Label("action.delete", systemImage: "trash")
                            }

                            Button {
                                editingRow = row
                            } label: {
                                Label("watchlist.action.edit", systemImage: "slider.horizontal.3")
                            }
                            .tint(AppColors.accent)
                        }
                    } else {
                        watchlistRowView(row)
                            .contentShape(Rectangle())
                            .onTapGesture { editingRow = row }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    Task { await viewModel.remove(symbol: row.entry.symbol) }
                                } label: {
                                    Label("action.delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .refreshable {
            HapticFeedback.lightImpact()
            await viewModel.load(forceRefresh: true)
            await container.priceTargetNotifier.notifyReachedTargets(in: viewModel.rows)
        }
    }

    private func summaryStrip(total: Int, reached: Int) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("watchlist.summary.tracked")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(total)")
                    .font(.headline.weight(.bold))
                    .monospacedDigit()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text("watchlist.summary.reached")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(reached)")
                    .font(.headline.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(reached > 0 ? AppColors.positive : .primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func watchlistRowView(_ row: WatchlistItemRow) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                if let definition = row.definition {
                    ClubBadgeView(definition: definition, size: 40)
                } else {
                    ClubBadgeView(symbol: row.entry.symbol, primaryColor: AppColors.accent, secondaryColor: .indigo, size: 40)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(row.entry.symbol)
                        .font(.headline)
                    Text(row.definition?.name ?? row.entry.symbol)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                if let token = row.token {
                    let movementColor = AppColors.priceMovement(token.ticker.changePercent24h)
                    VStack(alignment: .trailing, spacing: 3) {
                        Text(FanScopeFormatter.tryPrice(token.ticker.lastPriceTRY))
                            .font(.subheadline.weight(.semibold))
                            .monospacedDigit()
                        Text(FanScopeFormatter.signedPercentage(token.ticker.changePercent24h))
                            .font(.caption2.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(movementColor)
                    }
                } else {
                    Text("watchlist.status.offline")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if let target = row.entry.targetPriceTRY {
                HStack(spacing: 6) {
                    let symbolPrefix = row.entry.targetDirection == .above ? "≥" : "≤"
                    Image(systemName: row.targetStatus?.isReached == true ? "checkmark.circle.fill" : "bell.fill")
                        .font(.caption2)
                        .foregroundStyle(row.targetStatus?.isReached == true ? AppColors.positive : AppColors.accent)

                    Text("\(symbolPrefix) \(FanScopeFormatter.tryPrice(target))")
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()

                    Spacer()

                    if let status = row.targetStatus {
                        if status.isReached {
                            Text("watchlist.target.reached")
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(AppColors.positive)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(AppColors.positive.opacity(0.14), in: Capsule())
                        } else {
                            Text(FanScopeFormatter.signedPercentage(status.distancePercentage))
                                .font(.caption2.weight(.semibold))
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(AppColors.surfaceBackground, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }

            if !row.entry.note.isEmpty {
                Text(row.entry.note)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}
