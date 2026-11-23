import Charts
import FanScopeKit
import SwiftUI

struct InteractivePriceChartView: View {
    let token: FanToken
    @State private var selectedIndex: Int?

    private var points: [Double] { token.sparkline7dTRY }

    private var movementColor: Color {
        AppColors.priceMovement(token.ticker.changePercent24h)
    }

    private var yDomain: ClosedRange<Double> {
        guard let minValue = points.min(), let maxValue = points.max() else {
            return 0...1
        }
        let padding = max((maxValue - minValue) * 0.08, 0.01)
        return (minValue - padding)...(maxValue + padding)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if points.count >= 2 {
                chartHeader
                sparklineChart
            } else {
                dailyRangeCard
            }
        }
        .padding(16)
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var chartHeader: some View {
        HStack {
            Text("detail.chart.7d_trend")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Spacer()

            if let selectedIndex, points.indices.contains(selectedIndex) {
                let price = Decimal(points[selectedIndex])
                Text(FanScopeFormatter.tryPrice(price))
                    .font(.subheadline.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(movementColor)
            } else if let first = points.first, let last = points.last, first > 0 {
                let change7d = ((last - first) / first) * 100
                Text(FanScopeFormatter.signedPercentage(change7d))
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(AppColors.priceMovement(change7d))
            }
        }
    }

    private var sparklineChart: some View {
        Chart {
            ForEach(Array(points.enumerated()), id: \.offset) { index, value in
                LineMark(
                    x: .value("Hour", index),
                    y: .value("Price", value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(movementColor)
                .lineStyle(StrokeStyle(lineWidth: 2))

                AreaMark(
                    x: .value("Hour", index),
                    yStart: .value("Min", yDomain.lowerBound),
                    yEnd: .value("Price", value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [movementColor.opacity(0.24), movementColor.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }

            if let selectedIndex, points.indices.contains(selectedIndex) {
                RuleMark(x: .value("Selected", selectedIndex))
                    .foregroundStyle(Color.secondary.opacity(0.45))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))

                PointMark(
                    x: .value("Selected", selectedIndex),
                    y: .value("Price", points[selectedIndex])
                )
                .foregroundStyle(movementColor)
                .symbolSize(48)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                    .foregroundStyle(Color.secondary.opacity(0.2))
                AxisValueLabel {
                    if let numeric = value.as(Double.self) {
                        Text(FanScopeFormatter.tryPrice(Decimal(numeric)))
                            .font(.caption2)
                            .monospacedDigit()
                    }
                }
            }
        }
        .chartYScale(domain: yDomain)
        .chartXSelection(value: $selectedIndex)
        .onChange(of: selectedIndex) { oldValue, newValue in
            if newValue != nil && oldValue != newValue {
                HapticFeedback.selection()
            }
        }
        .frame(height: 170)
    }

    private var dailyRangeCard: some View {
        let low = NSDecimalNumber(decimal: token.ticker.low24hTRY).doubleValue
        let high = NSDecimalNumber(decimal: token.ticker.high24hTRY).doubleValue
        let current = NSDecimalNumber(decimal: token.ticker.lastPriceTRY).doubleValue
        let progress = high > low ? min(max((current - low) / (high - low), 0), 1) : 0.5

        return VStack(alignment: .leading, spacing: 10) {
            Text("detail.chart.24h_range")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.18))
                        .frame(height: 8)

                    Capsule()
                        .fill(movementColor.opacity(0.75))
                        .frame(width: max(8, proxy.size.width * progress), height: 8)

                    Circle()
                        .fill(movementColor)
                        .frame(width: 14, height: 14)
                        .offset(x: max(0, min(proxy.size.width - 14, (proxy.size.width - 14) * progress)))
                }
            }
            .frame(height: 14)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("detail.stats.low_24h")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(FanScopeFormatter.tryPrice(token.ticker.low24hTRY))
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("detail.stats.high_24h")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(FanScopeFormatter.tryPrice(token.ticker.high24hTRY))
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                }
            }
        }
    }
}
