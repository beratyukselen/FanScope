import FanScopeKit
import SwiftUI

struct OrderBookDepthView: View {
    let state: LoadState<OrderBookSnapshot>
    let onRetry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("detail.orderbook.title")
                    .font(.headline)
                Spacer()
                Text("Paribu")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.12), in: Capsule())
            }

            switch state {
            case .idle, .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 100)
            case .empty:
                Text("detail.orderbook.empty")
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
                orderBookContent(snapshot)
            }
        }
        .padding(16)
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func orderBookContent(_ snapshot: OrderBookSnapshot) -> some View {
        let bids = Array(snapshot.orderBook.bids.prefix(8))
        let asks = Array(snapshot.orderBook.asks.prefix(8))
        let maxAmount = max(
            bids.map(\.amount).max() ?? 1,
            asks.map(\.amount).max() ?? 1,
            1
        )
        let bidPct = Int((snapshot.summary.bidPressureRatio * 100).rounded())
        let askPct = 100 - bidPct

        return VStack(spacing: 12) {
            // Spread + Pressure bar
            VStack(spacing: 6) {
                HStack {
                    Text("detail.orderbook.bids_pct \(bidPct)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppColors.positive)
                    Spacer()
                    if let spreadTRY = snapshot.summary.spreadTRY,
                       let spreadPct = snapshot.summary.spreadPercentage {
                        Text(
                            "Spread: \(FanScopeFormatter.tryPrice(spreadTRY)) (\(String(format: "%.2f%%", spreadPct)))"
                        )
                        .font(.caption2)
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("detail.orderbook.asks_pct \(askPct)")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(AppColors.negative)
                }

                GeometryReader { proxy in
                    HStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(AppColors.positive.opacity(0.8))
                            .frame(width: max(4, proxy.size.width * snapshot.summary.bidPressureRatio))
                        RoundedRectangle(cornerRadius: 3)
                            .fill(AppColors.negative.opacity(0.8))
                    }
                }
                .frame(height: 6)
            }

            HStack(alignment: .top, spacing: 10) {
                // Bids column
                VStack(spacing: 4) {
                    HStack {
                        Text("detail.orderbook.amount")
                        Spacer()
                        Text("detail.orderbook.bid")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                    ForEach(Array(bids.enumerated()), id: \.offset) { _, level in
                        depthRow(
                            price: level.priceTRY,
                            amount: level.amount,
                            maxAmount: maxAmount,
                            color: AppColors.positive,
                            isBid: true
                        )
                    }
                }

                // Asks column
                VStack(spacing: 4) {
                    HStack {
                        Text("detail.orderbook.ask")
                        Spacer()
                        Text("detail.orderbook.amount")
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                    ForEach(Array(asks.enumerated()), id: \.offset) { _, level in
                        depthRow(
                            price: level.priceTRY,
                            amount: level.amount,
                            maxAmount: maxAmount,
                            color: AppColors.negative,
                            isBid: false
                        )
                    }
                }
            }
        }
    }

    private func depthRow(
        price: Decimal,
        amount: Double,
        maxAmount: Double,
        color: Color,
        isBid: Bool
    ) -> some View {
        let ratio = min(max(amount / maxAmount, 0.04), 1)
        return ZStack(alignment: isBid ? .trailing : .leading) {
            GeometryReader { proxy in
                color.opacity(0.14)
                    .frame(width: proxy.size.width * ratio)
                    .frame(maxWidth: .infinity, alignment: isBid ? .trailing : .leading)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            HStack {
                if isBid {
                    Text(FanScopeFormatter.compactTokenAmount(amount))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(FanScopeFormatter.tryPrice(price))
                        .foregroundStyle(color)
                        .fontWeight(.medium)
                } else {
                    Text(FanScopeFormatter.tryPrice(price))
                        .foregroundStyle(color)
                        .fontWeight(.medium)
                    Spacer()
                    Text(FanScopeFormatter.compactTokenAmount(amount))
                        .foregroundStyle(.secondary)
                }
            }
            .font(.caption2)
            .monospacedDigit()
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
        }
        .frame(height: 24)
    }
}
