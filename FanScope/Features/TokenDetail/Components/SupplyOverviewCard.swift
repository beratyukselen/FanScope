import FanScopeKit
import SwiftUI

struct SupplyOverviewCard: View {
    let symbol: String
    let network: BlockchainNetwork
    let supply: SupplyMetrics
    let monthlySummary: MonthlyFlowSummary?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("detail.supply.title")
                    .font(.headline)
                Spacer()
                Text("\(network.displayName) · \(network.tokenStandard)")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.12), in: Capsule())
            }

            if let ratio = supply.circulatingRatio {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("detail.supply.circulating_ratio")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(String(format: "%.1f%%", ratio * 100))
                            .font(.caption.weight(.bold))
                            .monospacedDigit()
                    }
                    ProgressView(value: ratio)
                        .tint(AppColors.accent)
                }
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                metricCell(
                    title: "detail.supply.total",
                    value: supply.totalSupply.map { "\(FanScopeFormatter.compactTokenAmount($0)) \(symbol)" } ?? "—"
                )
                metricCell(
                    title: "detail.supply.circulating",
                    value: supply.circulatingSupply.map { "\(FanScopeFormatter.compactTokenAmount($0)) \(symbol)" } ?? "—"
                )
                metricCell(
                    title: "detail.supply.max",
                    value: supply.maxSupply.map { "\(FanScopeFormatter.compactTokenAmount($0)) \(symbol)" } ?? "—"
                )
                metricCell(
                    title: "detail.supply.holders",
                    value: supply.holdersCount.map { $0.formatted() } ?? "—"
                )
            }

            if let summary = monthlySummary {
                Divider()

                Text("detail.flows.window_30d")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    metricCell(
                        title: "detail.flows.minted",
                        value: summary.mintedAmount > 0
                            ? "+\(FanScopeFormatter.compactTokenAmount(summary.mintedAmount))"
                            : "0",
                        tint: summary.mintedAmount > 0 ? AppColors.warning : .primary
                    )
                    metricCell(
                        title: "detail.flows.burned",
                        value: summary.burnedAmount > 0
                            ? "-\(FanScopeFormatter.compactTokenAmount(summary.burnedAmount))"
                            : "0",
                        tint: summary.burnedAmount > 0 ? AppColors.positive : .primary
                    )
                    metricCell(
                        title: "detail.flows.outflow",
                        value: FanScopeFormatter.compactTokenAmount(summary.exchangeOutflowAmount),
                        tint: AppColors.positive
                    )
                    metricCell(
                        title: "detail.flows.inflow",
                        value: FanScopeFormatter.compactTokenAmount(summary.exchangeInflowAmount),
                        tint: AppColors.negative
                    )
                }
            }
        }
        .padding(16)
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func metricCell(
        title: LocalizedStringKey,
        value: String,
        tint: Color = .primary
    ) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(AppColors.surfaceBackground, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
