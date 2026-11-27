import FanScopeKit
import SwiftUI

struct OnChainActivitySection: View {
    let symbol: String
    let network: BlockchainNetwork
    let state: LoadState<OnChainSnapshot>
    @Binding var selectedTab: OnChainSectionTab
    @Binding var selectedFilter: OnChainFlowFilter
    let filteredEvents: [OnChainEvent]
    let onRetry: () -> Void
    let onSelectURL: (URL) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("detail.onchain.title")
                    .font(.headline)
                Spacer()
                Text(network.displayName)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Picker("detail.onchain.title", selection: $selectedTab) {
                Text("detail.onchain.tab.activity").tag(OnChainSectionTab.activity)
                Text("detail.onchain.tab.holders").tag(OnChainSectionTab.holders)
            }
            .pickerStyle(.segmented)

            switch state {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 120)
            case .empty:
                Text("detail.onchain.empty")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            case .failed(let message):
                VStack(spacing: 8) {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("action.try_again", action: onRetry)
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            case .loaded(let snapshot):
                if selectedTab == .activity {
                    activityTabContent
                } else {
                    holdersTabContent(snapshot.holders)
                }
            }
        }
        .padding(16)
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var activityTabContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(OnChainFlowFilter.allCases) { filter in
                        let isSelected = selectedFilter == filter
                        Button {
                            HapticFeedback.selection()
                            selectedFilter = filter
                        } label: {
                            Text(filter.localizedTitleKey)
                                .font(.caption2.weight(.semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .foregroundStyle(isSelected ? .white : .primary)
                                .background(
                                    isSelected ? AppColors.accent : AppColors.surfaceBackground,
                                    in: Capsule()
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if filteredEvents.isEmpty {
                Text("detail.onchain.no_matching_events")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 18)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(filteredEvents.prefix(20)) { event in
                        eventRow(event)
                    }
                }
            }
        }
    }

    private func eventRow(_ event: OnChainEvent) -> some View {
        let badgeColor = event.kind.tintColor
        return Button {
            if let url = event.explorerURL {
                onSelectURL(url)
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(event.kind.localizedBadgeKey)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(badgeColor)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(badgeColor.opacity(0.15), in: Capsule())

                    Spacer()

                    Text("\(FanScopeFormatter.compactTokenAmount(event.amount)) \(symbol)")
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(.primary)

                    Image(systemName: "arrow.up.right")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                HStack(spacing: 4) {
                    Text(event.fromLabel ?? FanScopeFormatter.shortenedAddress(event.fromAddress))
                        .lineLimit(1)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                    Text(event.toLabel ?? FanScopeFormatter.shortenedAddress(event.toAddress))
                        .lineLimit(1)
                    Spacer()
                    Text(event.timestamp, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding(10)
            .background(AppColors.surfaceBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func holdersTabContent(_ holders: [TokenHolder]) -> some View {
        Group {
            if holders.isEmpty {
                Text("detail.onchain.no_holders")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 18)
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(Array(holders.enumerated()), id: \.element.id) { index, holder in
                        Button {
                            if let url = network.addressURL(address: holder.address) {
                                onSelectURL(url)
                            }
                        } label: {
                            HStack(spacing: 10) {
                                Text(verbatim: "#\(index + 1)")
                                    .font(.caption.weight(.bold))
                                    .monospacedDigit()
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .frame(width: 30, alignment: .leading)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(holder.label ?? FanScopeFormatter.shortenedAddress(holder.address))
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.primary)
                                        .lineLimit(1)

                                    if holder.label != nil {
                                        Text(FanScopeFormatter.shortenedAddress(holder.address))
                                            .font(.caption2)
                                            .monospacedDigit()
                                            .foregroundStyle(.secondary)
                                    }
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 2) {
                                    Text("\(FanScopeFormatter.compactTokenAmount(holder.balance)) \(symbol)")
                                        .font(.subheadline.weight(.semibold))
                                        .monospacedDigit()
                                        .foregroundStyle(.primary)

                                    if let share = holder.sharePercentage {
                                        Text(String(format: "%.2f%%", share))
                                            .font(.caption2)
                                            .monospacedDigit()
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(10)
                            .background(AppColors.surfaceBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private extension OnChainFlowFilter {
    var localizedTitleKey: LocalizedStringKey {
        switch self {
        case .all: return "detail.onchain.filter.all"
        case .supplyChanges: return "detail.onchain.filter.mint_burn"
        case .exchangeFlows: return "detail.onchain.filter.exchange"
        }
    }
}

private extension OnChainFlowKind {
    var localizedBadgeKey: LocalizedStringKey {
        switch self {
        case .mint: return "flow.kind.mint"
        case .burn: return "flow.kind.burn"
        case .exchangeOutflow: return "flow.kind.outflow"
        case .exchangeInflow: return "flow.kind.inflow"
        case .exchangeInternal: return "flow.kind.internal"
        case .transfer: return "flow.kind.transfer"
        }
    }

    var tintColor: Color {
        switch self {
        case .mint: return AppColors.warning
        case .burn, .exchangeOutflow: return AppColors.positive
        case .exchangeInflow: return AppColors.negative
        case .exchangeInternal, .transfer: return .secondary
        }
    }
}
